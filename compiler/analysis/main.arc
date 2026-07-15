// Semantic analysis pass for the Artemis self-hosting compiler.
// Performs:
//   1. Two-pass symbol collection (top-level names before body analysis)
//   2. Duplicate local declaration detection
//   3. Basic undefined-identifier warning (soft — IR layer resolves many names)
//   4. Walk of all expressions and statements for future analysis hooks

namespace analysis {

// ---- Analysis context ----

struct ana_ctx {
    scope_manager scope;
    i32           error_count;
    bool          in_func;
    i8*           cur_func_name;
    bool          cur_func_is_void;
    bool          cur_func_is_error_union;  // true if current function returns !T
    bool          cur_func_has_memstr_param; // true if current function has &memstr param
    bool          cur_func_is_main;         // true if current function is main()
    bool          cur_func_in_istruc;       // true if current function is a method of an istruc
    bool          cur_func_in_memstr_istruc; // true if current function is inside a memstr-declared type
    bool          in_loop;
    bool          in_generic;  // inside a generic namespace/struct — skip type param checking
    bool          is_unsafe;   // true when compiled with --unsafe flag
}

void ana_error(ana_ctx* ctx, u64 line, i8* msg) {
    printf("semantic error at line %d: %s\n", (i32)line, msg);
    ctx.error_count = ctx.error_count + 1;
}

// ---- Forward declarations ----
void ana_stmt(parser.ast_node* node, ana_ctx* ctx);
void ana_expr(parser.expr_node* e, ana_ctx* ctx);
void ana_block(parser.block_stmt* blk, ana_ctx* ctx);
i32 analyze_unsafe(parser.program_node* prog, bool unsafe_mode);

// ---- Type validity helper ----

bool is_type_known(parser.type_node* t, ana_ctx* ctx) {
    if (t == (parser.type_node*)0) { return true; }
    if (t.is_primitive) { return true; }
    if (t.is_auto) { return true; }
    if (t.is_func_ptr) { return true; }
    if (t.is_self_type || t.is_self_ref) { return true; }
    if (t.is_sta || t.is_interface) { return true; }
    if (t.name == (i8*)0) { return true; }
    // Skip compiler-internal names (__xxx)
    if (t.name[0] == '_' && t.name[1] == '_') { return true; }
    // Skip lowercase-starting names: primitives (n8, z16), builtins (type_info, tokenstream, memstr)
    if (t.name[0] >= 'a' && t.name[0] <= 'z') { return true; }
    // Skip namespace-mangled names (geom__NS_Point etc.)
    if (strstr(t.name, "__NS_") != (i8*)0) { return true; }
    if (ctx.scope.exists(t.name)) { return true; }
    if (ctx.scope.lookup_struct(t.name) != (i8*)0) { return true; }
    return false;
}

// ---- Expression analysis ----

void ana_expr(parser.expr_node* e, ana_ctx* ctx) {
    if (e == (parser.expr_node*)0) { return; }
    i32 kind = e.kind;

    if (kind == ek_identifier) {
        if (ctx.in_func && e.str_val != (i8*)0) {
            // Skip compiler-internal names (e.g. __derive_Debug_Point, __construct__)
            bool is_internal = (e.str_val[0] == '_' && e.str_val[1] == '_');
            // Skip namespace-mangled names used as type expressions (e.g. sizeof(lexer__NS_token_t))
            bool is_ns_mangled = (strstr(e.str_val, "__NS_") != (i8*)0);
            if (!is_internal && !is_ns_mangled && !ctx.scope.exists(e.str_val)) {
                // Also check struct registry (e.g. sizeof(MyStruct) where MyStruct is expr)
                if (ctx.scope.lookup_struct(e.str_val) == (i8*)0) {
                    i8 msg[256];
                    snprintf(msg, (u64)256, "undefined identifier '%s'", e.str_val);
                    ana_error(ctx, e.line, msg);
                }
            }
        }
        return;
    }

    if (kind == ek_call) {
        if (e.callee != (parser.expr_node*)0) { ana_expr(e.callee, ctx); }
        i32 ai = 0;
        while (ai < e.args_len) {
            if (e.args != (parser.expr_node**)0) { ana_expr(e.args[ai], ctx); }
            ai = ai + 1;
        }
        // Check callee for simple identifier callees
        if (e.callee != (parser.expr_node*)0 && e.callee.kind == (i32)ek_identifier &&
            e.callee.str_val != (i8*)0) {
            i8* fname = e.callee.str_val;
            bool is_internal = (fname[0] == '_' && fname[1] == '_');
            if (!is_internal) {
                i32 callee_kind = ctx.scope.lookup_kind(fname);
                // sym_func_ptr (=4) is a function pointer variable — callable, skip
                if (callee_kind == (i32)sym_var) {
                    i8 msg[256];
                    snprintf(msg, (u64)256, "'%s' is not callable (declared as a variable)", fname);
                    ana_error(ctx, e.line, msg);
                } else if (callee_kind == (i32)sym_func) {
                    bool is_var = ctx.scope.lookup_is_variadic(fname);
                    if (!is_var) {
                        i32 expected = ctx.scope.lookup_param_count(fname);
                        if (expected >= 0 && e.args_len != expected) {
                            i8 msg[256];
                            snprintf(msg, (u64)256, "wrong number of arguments to '%s': expected %d, got %d", fname, expected, e.args_len);
                            ana_error(ctx, e.line, msg);
                        }
                    }
                    // Enforce allocator discipline: raw heap operations only inside memstr-declared types.
                    // No exemptions for main() or functions with &memstr params — they must use the allocator.
                    if (!ctx.in_generic && ctx.in_func && !ctx.is_unsafe &&
                        !ctx.cur_func_in_memstr_istruc) {
                        bool is_heap_op = (strcmp(fname, "malloc")  == 0 ||
                                           strcmp(fname, "realloc") == 0 ||
                                           strcmp(fname, "calloc")  == 0 ||
                                           strcmp(fname, "free")    == 0);
                        if (is_heap_op) {
                            i8 msg[256];
                            snprintf(msg, (u64)256, "direct heap operation ('%s') not allowed outside a 'memstr' allocator type", fname);
                            ana_error(ctx, e.line, msg);
                        }
                    }
                    // Check nullable arg to non-nullable param, and non-memstr arg to &memstr param
                    if (!ctx.in_generic && ctx.in_func) {
                        i8* fd_ptr = ctx.scope.lookup(fname);
                        if (fd_ptr != (i8*)0) {
                            parser.func_decl* cfd2 = (parser.func_decl*)fd_ptr;
                            i32 nai = 0;
                            while (nai < e.args_len && nai < cfd2.params_len) {
                                parser.expr_node* arg_e = (e.args != (parser.expr_node**)0) ? e.args[nai] : (parser.expr_node*)0;
                                if (arg_e != (parser.expr_node*)0 && arg_e.kind == (i32)ek_identifier &&
                                    arg_e.str_val != (i8*)0) {
                                    bool arg_nullable = ctx.scope.lookup_is_nullable(arg_e.str_val);
                                    if (arg_nullable) {
                                        parser.param_decl* pd = (cfd2.params != (parser.param_decl*)0) ?
                                            &cfd2.params[nai] : (parser.param_decl*)0;
                                        if (pd != (parser.param_decl*)0 && pd.type != (parser.type_node*)0) {
                                            if (!pd.type.is_nullable && pd.type.pointer_depth == 0 && !pd.type.is_func_ptr) {
                                                i8 msg[256];
                                                snprintf(msg, (u64)256, "cannot pass nullable value as non-nullable parameter '%s'", pd.name != (i8*)0 ? pd.name : "?");
                                                ana_error(ctx, e.line, msg);
                                            }
                                        }
                                    }
                                    // Check non-memstr arg to &memstr param
                                    if (!ctx.is_unsafe && cfd2.params != (parser.param_decl*)0) {
                                        parser.param_decl param_nai = cfd2.params[nai];
                                        if (param_nai.type != (parser.type_node*)0 && param_nai.type.is_memstr_ref) {
                                            // Arg must be a memstr-type variable
                                            i8* arg_type_ptr = ctx.scope.lookup(arg_e.str_val);
                                            bool arg_is_memstr = false;
                                            if (arg_type_ptr != (i8*)0 && arg_type_ptr != (i8*)1) {
                                                parser.var_decl* arg_vd = (parser.var_decl*)arg_type_ptr;
                                                if (arg_vd.type != (parser.type_node*)0 && !arg_vd.type.is_primitive &&
                                                    arg_vd.type.name != (i8*)0) {
                                                    i8* arg_type_name = arg_vd.type.name;
                                                    i8* arg_ns = ctx.scope.lookup(arg_type_name);
                                                    if (arg_ns != (i8*)0 && arg_ns != (i8*)1) {
                                                        parser.namespace_decl* arg_nd = (parser.namespace_decl*)arg_ns;
                                                        if (arg_nd.is_memstr) { arg_is_memstr = true; }
                                                    }
                                                }
                                            }
                                            if (!arg_is_memstr) {
                                                i8 msg[256];
                                                snprintf(msg, (u64)256, "argument '%s' is not a 'memstr' allocator (parameter requires '&memstr')", arg_e.str_val);
                                                ana_error(ctx, e.line, msg);
                                            }
                                        }
                                    }
                                }
                                nai = nai + 1;
                            }
                        }
                    }
                }
            }
        }
        // Check method call arg count: callee is obj.method(args...)
        if (ctx.in_func && !ctx.in_generic && e.callee != (parser.expr_node*)0 &&
            e.callee.kind == (i32)ek_member && e.callee.object != (parser.expr_node*)0 &&
            e.callee.object.kind == (i32)ek_identifier && e.callee.object.str_val != (i8*)0 &&
            e.callee.member_name != (i8*)0) {
            i8* obj_name = e.callee.object.str_val;
            i8* meth_name = e.callee.member_name;
            bool is_construct_call = (strcmp(meth_name, "__construct__") == 0);
            // __construct__ can only be called on comptime variables
            if (is_construct_call && ctx.scope.lookup_kind(obj_name) == (i32)sym_var) {
                bool obj_is_comptime = ctx.scope.lookup_is_comptime(obj_name);
                if (!obj_is_comptime) {
                    i8 msg[256];
                    snprintf(msg, (u64)256, "cannot call '__construct__' on '%s': variable was not declared with 'comptime'", obj_name);
                    ana_error(ctx, e.line, msg);
                }
            }
            bool is_internal_m = (meth_name[0] == '_' && meth_name[1] == '_');
            if (!is_internal_m && ctx.scope.lookup_kind(obj_name) == (i32)sym_var) {
                i8* type_ptr_m = ctx.scope.lookup(obj_name);
                if (type_ptr_m != (i8*)0 && type_ptr_m != (i8*)1) {
                    parser.var_decl* mvd = (parser.var_decl*)type_ptr_m;
                    if (mvd.type != (parser.type_node*)0 && !mvd.type.is_primitive &&
                        mvd.type.name != (i8*)0) {
                        i8* type_name_m = mvd.type.name;
                        i8* ns_ptr_m = ctx.scope.lookup(type_name_m);
                        if (ns_ptr_m != (i8*)0 && ns_ptr_m != (i8*)1) {
                            parser.namespace_decl* mns = (parser.namespace_decl*)ns_ptr_m;
                            // Find the method in the namespace and count its non-self params
                            i32 mdi = 0;
                            while (mdi < mns.decls_len) {
                                parser.ast_node* mdchild = (mns.decls != (parser.ast_node**)0) ? mns.decls[mdi] : (parser.ast_node*)0;
                                if (mdchild != (parser.ast_node*)0 && mdchild.kind == nd_func_decl) {
                                    parser.func_decl* mfd2 = (parser.func_decl*)mdchild;
                                    if (mfd2.name != (i8*)0 && strcmp(mfd2.name, meth_name) == 0) {
                                        if (!mfd2.is_variadic) {
                                            // Detect explicit self: first param is pointer to the struct type
                                            bool first_is_self = false;
                                            if (mfd2.params_len > 0 && mfd2.params != (parser.param_decl*)0) {
                                                parser.type_node* fp = mfd2.params[0].type;
                                                if (fp != (parser.type_node*)0 && fp.pointer_depth > 0 &&
                                                    fp.name != (i8*)0 && mns.name != (i8*)0 &&
                                                    strcmp(fp.name, mns.name) == 0) {
                                                    first_is_self = true;
                                                }
                                            }
                                            i32 non_self = first_is_self ? mfd2.params_len - 1 : mfd2.params_len;
                                            if (e.args_len != non_self) {
                                                i8 msg[256];
                                                snprintf(msg, (u64)256, "wrong number of arguments to method '%s': expected %d, got %d", meth_name, non_self, e.args_len);
                                                ana_error(ctx, e.line, msg);
                                            }
                                        }
                                        break;
                                    }
                                }
                                mdi = mdi + 1;
                            }
                        }
                    }
                }
            }
        }
        return;
    }

    if (kind == (i32)ek_sizeof_e) {
        if (!ctx.in_generic && e.cast_type != (parser.type_node*)0 && !is_type_known(e.cast_type, ctx)) {
            if (e.cast_type.name != (i8*)0) {
                i8 msg[256];
                snprintf(msg, (u64)256, "unknown type '%s' in sizeof", e.cast_type.name);
                ana_error(ctx, e.line, msg);
            }
        }
        if (e.operand != (parser.expr_node*)0) { ana_expr(e.operand, ctx); }
        return;
    }

    if (kind == ek_assign || kind == ek_binary) {
        ana_expr(e.lhs, ctx);
        ana_expr(e.rhs, ctx);
        return;
    }

    if (kind == ek_unary) {
        ana_expr(e.operand, ctx);
        // Check: dereference of a non-pointer local variable
        if (e.uop == (i32)uop_deref && !ctx.in_generic && ctx.in_func &&
            e.operand != (parser.expr_node*)0 && e.operand.kind == (i32)ek_identifier &&
            e.operand.str_val != (i8*)0) {
            i8* op_name = e.operand.str_val;
            if (ctx.scope.lookup_kind(op_name) == (i32)sym_var) {
                i8* type_ptr2 = ctx.scope.lookup(op_name);
                if (type_ptr2 != (i8*)0 && type_ptr2 != (i8*)1) {
                    parser.var_decl* dvd = (parser.var_decl*)type_ptr2;
                    // Only error for primitives (typedef aliases may resolve to pointer types)
                    if (dvd.type != (parser.type_node*)0 && dvd.type.pointer_depth == 0 &&
                        !dvd.type.is_func_ptr && dvd.type.is_primitive) {
                        i8 msg[256];
                        snprintf(msg, (u64)256, "cannot dereference non-pointer variable '%s'", op_name);
                        ana_error(ctx, e.line, msg);
                    }
                }
            }
        }
        return;
    }

    if (kind == ek_ternary) {
        ana_expr(e.cond, ctx);
        ana_expr(e.then_e, ctx);
        ana_expr(e.else_e, ctx);
        return;
    }

    if (kind == ek_member) {
        ana_expr(e.object, ctx);
        // Check: member access on a void-returning function call
        if (ctx.in_func && !ctx.in_generic && e.object != (parser.expr_node*)0 &&
            e.object.kind == (i32)ek_call) {
            parser.expr_node* callee_e = e.object.callee;
            if (callee_e != (parser.expr_node*)0 && callee_e.kind == (i32)ek_identifier &&
                callee_e.str_val != (i8*)0) {
                if (ctx.scope.lookup_is_void_ret(callee_e.str_val)) {
                    i8 msg[256];
                    snprintf(msg, (u64)256, "member access on void return type (function '%s' returns void)", callee_e.str_val);
                    ana_error(ctx, e.line, msg);
                }
            }
        }
        // Type check: member access on a known type
        if (ctx.in_func && !ctx.in_generic && e.object != (parser.expr_node*)0 &&
            e.member_name != (i8*)0 && e.object.kind == (i32)ek_identifier &&
            e.object.str_val != (i8*)0) {
            i8* obj_name = e.object.str_val;
            bool is_internal = (obj_name[0] == '_' && obj_name[1] == '_');
            if (!is_internal && ctx.scope.lookup_kind(obj_name) == (i32)sym_var) {
                i8* type_ptr = ctx.scope.lookup(obj_name);
                // type_ptr == (i8*)vd for local vars — check if it looks like a valid pointer
                if (type_ptr != (i8*)0 && type_ptr != (i8*)1) {
                    parser.var_decl* vd = (parser.var_decl*)type_ptr;
                    if (vd.type != (parser.type_node*)0) {
                        // Primitive type: no members (except complex/rational which have .re/.im/.num/.den)
                        i32 prim_val = vd.type.prim;
                        bool is_compound_prim = (prim_val == 6 || prim_val == 7); // arb_rational=6, arb_complex=7
                        if (vd.type.is_primitive && vd.type.pointer_depth == 0 && !vd.type.is_func_ptr && !is_compound_prim) {
                            i8 msg[256];
                            snprintf(msg, (u64)256, "member access on primitive type (no members)");
                            ana_error(ctx, e.line, msg);
                        } else if (!vd.type.is_primitive && vd.type.name != (i8*)0) {
                            // Named type: check if member exists
                            i8* type_name = vd.type.name;
                            bool member_found = false;
                            // Check as namespace_decl (istruc)
                            i8* ns_ptr = ctx.scope.lookup(type_name);
                            if (ns_ptr != (i8*)0 && ns_ptr != (i8*)1) {
                                parser.namespace_decl* mnd = (parser.namespace_decl*)ns_ptr;
                                // Check struct_decl child (first child) for fields
                                i32 di = 0;
                                while (di < mnd.decls_len && !member_found) {
                                    parser.ast_node* dchild = (mnd.decls != (parser.ast_node**)0) ? mnd.decls[di] : (parser.ast_node*)0;
                                    if (dchild != (parser.ast_node*)0) {
                                        if (dchild.kind == nd_struct_decl) {
                                            parser.struct_decl* fsd = (parser.struct_decl*)dchild;
                                            i32 fi = 0;
                                            while (fi < fsd.fields_len && !member_found) {
                                                parser.var_decl** flds = fsd.fields;
                                                parser.var_decl* fld = (flds != (parser.var_decl**)0) ? flds[fi] : (parser.var_decl*)0;
                                                if (fld != (parser.var_decl*)0 && fld.name != (i8*)0) {
                                                    if (strcmp(fld.name, e.member_name) == 0) { member_found = true; }
                                                }
                                                fi = fi + 1;
                                            }
                                        } else if (dchild.kind == nd_func_decl) {
                                            parser.func_decl* mfd = (parser.func_decl*)dchild;
                                            if (mfd.name != (i8*)0 && strcmp(mfd.name, e.member_name) == 0) {
                                                member_found = true;
                                            }
                                        }
                                    }
                                    di = di + 1;
                                }
                            }
                            // Check as struct in struct registry
                            i8* sd_ptr = ctx.scope.lookup_struct(type_name);
                            if (!member_found && sd_ptr != (i8*)0) {
                                parser.struct_decl* sd = (parser.struct_decl*)sd_ptr;
                                if (sd.kind == nd_struct_decl) {
                                    i32 fi = 0;
                                    while (fi < sd.fields_len && !member_found) {
                                        parser.var_decl** sflds = sd.fields;
                                        parser.var_decl* sfld = (sflds != (parser.var_decl**)0) ? sflds[fi] : (parser.var_decl*)0;
                                        if (sfld != (parser.var_decl*)0 && sfld.name != (i8*)0) {
                                            if (strcmp(sfld.name, e.member_name) == 0) { member_found = true; }
                                        }
                                        fi = fi + 1;
                                    }
                                }
                            }
                            if (!member_found && ns_ptr != (i8*)0 && ns_ptr != (i8*)1) {
                                // Known istruc type but member not found
                                i8 msg[256];
                                snprintf(msg, (u64)256, "no member '%s' in type '%s'", e.member_name, type_name);
                                ana_error(ctx, e.line, msg);
                            } else if (!member_found && sd_ptr != (i8*)0) {
                                i8 msg[256];
                                snprintf(msg, (u64)256, "no field '%s' in struct/union '%s'", e.member_name, type_name);
                                ana_error(ctx, e.line, msg);
                            }
                        }
                    }
                }
            }
        }
        return;
    }
    if (kind == ek_subscript) { ana_expr(e.object, ctx); ana_expr(e.index, ctx); return; }
    if (kind == ek_cast)      { ana_expr(e.operand, ctx); return; }

    if (kind == ek_null_coal) {
        ana_expr(e.lhs, ctx);
        ana_expr(e.rhs, ctx);
        return;
    }

    if (kind == ek_lambda) {
        ctx.scope.push_scope();
        // Register captures and parameters so their uses inside the body aren't flagged
        i32 ci = 0;
        while (ci < e.lambda_cap_len) {
            if (e.lambda_cap_names != (i8**)0 && e.lambda_cap_names[ci] != (i8*)0) {
                ctx.scope.declare(e.lambda_cap_names[ci], sym_var, (i8*)0);
            }
            ci = ci + 1;
        }
        i32 lpi = 0;
        while (lpi < e.lambda_param_len) {
            if (e.lambda_param_names != (i8**)0 && e.lambda_param_names[lpi] != (i8*)0) {
                ctx.scope.declare(e.lambda_param_names[lpi], sym_var, (i8*)0);
            }
            lpi = lpi + 1;
        }
        if (e.lambda_body != (i8*)0) {
            ana_block((parser.block_stmt*)e.lambda_body, ctx);
        }
        ctx.scope.pop_scope();
        return;
    }

    if (kind == (i32)ek_try_expr) {
        // 'try' is only valid inside a function returning !T (error union)
        if (ctx.in_func && !ctx.cur_func_is_error_union && !ctx.in_generic) {
            i8 msg[256];
            snprintf(msg, (u64)256, "'try' cannot be used in function '%s' which does not return an error union (!T)",
                     ctx.cur_func_name != (i8*)0 ? ctx.cur_func_name : "?");
            ana_error(ctx, e.line, msg);
        }
        if (e.operand != (parser.expr_node*)0) { ana_expr(e.operand, ctx); }
        return;
    }
}

// ---- Statement analysis ----

void ana_stmt(parser.ast_node* node, ana_ctx* ctx) {
    if (node == (parser.ast_node*)0) { return; }
    i32 kind = node.kind;

    if (kind == nd_var_decl) {
        parser.var_decl* vd = (parser.var_decl*)node;
        // comptime var cannot have constructor args at declaration site
        if (vd.is_constexpr && vd.has_ctor_parens && vd.ctor_args_len > 0 && !ctx.in_generic) {
            i8 msg[256];
            snprintf(msg, (u64)256, "'comptime' variable '%s' cannot have constructor arguments at declaration", vd.name != (i8*)0 ? vd.name : "?");
            ana_error(ctx, vd.line, msg);
        }
        // Check the declared type is known (skip in generic context)
        if (!ctx.in_generic && vd.type != (parser.type_node*)0 && !is_type_known(vd.type, ctx)) {
            if (vd.type.name != (i8*)0) {
                i8 msg[256];
                snprintf(msg, (u64)256, "unknown type '%s'", vd.type.name);
                ana_error(ctx, vd.line, msg);
            }
        }
        if (vd.name != (i8*)0) {
            // Duplicate local check within the same scope depth only
            if (ctx.in_func) {
                bool dup = ctx.scope.lookup_at_depth(vd.name);
                if (dup) {
                    i8 msg[256];
                    snprintf(msg, (u64)256, "duplicate declaration of '%s' in same scope", vd.name);
                    ana_error(ctx, vd.line, msg);
                } else {
                    // Declare as sym_func_ptr if the type is a function pointer or init is lambda
                    bool is_fptr = (vd.type != (parser.type_node*)0 && vd.type.is_func_ptr);
                    bool is_lambda_init = (vd.init != (parser.expr_node*)0 && vd.init.kind == (i32)ek_lambda);
                    i32 var_kind = (is_fptr || is_lambda_init) ? (i32)sym_func_ptr : (i32)sym_var;
                    bool var_nullable = (vd.type != (parser.type_node*)0 && vd.type.is_nullable);
                    ctx.scope.declare_var_comptime(vd.name, var_kind, (i8*)vd, var_nullable, vd.is_constexpr);
                }
            }
        }
        // Check: nullable variable assigned to a non-nullable, non-pointer, non-auto local
        if (vd.init != (parser.expr_node*)0 && vd.init.kind == (i32)ek_identifier &&
            vd.init.str_val != (i8*)0 && vd.type != (parser.type_node*)0 &&
            !vd.type.is_nullable && !vd.type.is_auto && !ctx.in_generic) {
            bool init_is_nullable = ctx.scope.lookup_is_nullable(vd.init.str_val);
            if (init_is_nullable) {
                i8 msg[256];
                if (vd.name != (i8*)0) {
                    snprintf(msg, (u64)256, "cannot assign nullable value to non-nullable variable '%s'", vd.name);
                } else {
                    snprintf(msg, (u64)256, "cannot assign nullable value to non-nullable type");
                }
                ana_error(ctx, vd.line, msg);
            }
        }
        // Check: null assigned to a non-pointer, non-nullable type
        if (vd.init != (parser.expr_node*)0 && vd.init.kind == (i32)ek_null_lit &&
            vd.type != (parser.type_node*)0 && !ctx.in_generic) {
            bool is_ptr      = (vd.type.pointer_depth > 0 || vd.type.is_func_ptr);
            bool is_nullable = vd.type.is_nullable;
            bool is_auto     = vd.type.is_auto;
            if (!is_ptr && !is_nullable && !is_auto) {
                i8 msg[256];
                if (vd.name != (i8*)0) {
                    snprintf(msg, (u64)256, "cannot assign null to non-pointer variable '%s'", vd.name);
                } else {
                    snprintf(msg, (u64)256, "cannot assign null to non-pointer type");
                }
                ana_error(ctx, vd.line, msg);
            }
        }
        if (vd.init != (parser.expr_node*)0) { ana_expr(vd.init, ctx); }
        return;
    }

    if (kind == nd_expr_stmt) {
        parser.expr_stmt* es = (parser.expr_stmt*)node;
        if (es.expr != (parser.expr_node*)0) {
            // Macro expansions may produce a nd_var_decl embedded as an expr
            if (es.expr.kind == nd_var_decl) {
                ana_stmt((parser.ast_node*)es.expr, ctx);
            } else {
                ana_expr(es.expr, ctx);
            }
        }
        return;
    }

    if (kind == nd_return_stmt) {
        parser.return_stmt* rs = (parser.return_stmt*)node;
        if (rs.val != (parser.expr_node*)0) { ana_expr(rs.val, ctx); }
        return;
    }

    if (kind == nd_if_stmt) {
        parser.if_stmt* is = (parser.if_stmt*)node;
        if (is.cond != (parser.expr_node*)0) { ana_expr(is.cond, ctx); }
        ctx.scope.push_scope();
        // If there's a capture variable (|p|), register it for the then-branch
        if (is.then_capture != (i8*)0) {
            ctx.scope.declare(is.then_capture, sym_var, (i8*)0);
        }
        if (is.then_body != (parser.ast_node*)0) { ana_stmt(is.then_body, ctx); }
        ctx.scope.pop_scope();
        if (is.else_body != (parser.ast_node*)0) {
            ctx.scope.push_scope();
            // If there's an else capture variable (|y|), register it
            if (is.else_capture != (i8*)0) {
                ctx.scope.declare(is.else_capture, sym_var, (i8*)0);
            }
            ana_stmt(is.else_body, ctx);
            ctx.scope.pop_scope();
        }
        return;
    }

    if (kind == nd_break_stmt || kind == nd_continue_stmt) {
        if (!ctx.in_loop) {
            i8* kw = kind == nd_break_stmt ? "break" : "continue";
            i8 msg[128];
            snprintf(msg, (u64)128, "'%s' used outside a loop", kw);
            ana_error(ctx, node.line, msg);
        }
        return;
    }

    if (kind == nd_while_stmt) {
        parser.while_stmt* ws = (parser.while_stmt*)node;
        if (ws.cond != (parser.expr_node*)0) { ana_expr(ws.cond, ctx); }
        bool outer_in_loop = ctx.in_loop;
        ctx.in_loop = true;
        ctx.scope.push_scope();
        if (ws.body != (parser.ast_node*)0) { ana_stmt(ws.body, ctx); }
        ctx.scope.pop_scope();
        ctx.in_loop = outer_in_loop;
        return;
    }

    if (kind == nd_for_stmt) {
        parser.for_stmt* fs = (parser.for_stmt*)node;
        ctx.scope.push_scope();
        if (fs.init != (parser.ast_node*)0) { ana_stmt(fs.init, ctx); }
        if (fs.cond != (parser.expr_node*)0) { ana_expr(fs.cond, ctx); }
        if (fs.step != (parser.expr_node*)0) { ana_expr(fs.step, ctx); }
        bool outer_in_loop_f = ctx.in_loop;
        ctx.in_loop = true;
        if (fs.body != (parser.ast_node*)0) { ana_stmt(fs.body, ctx); }
        ctx.in_loop = outer_in_loop_f;
        ctx.scope.pop_scope();
        return;
    }

    if (kind == nd_for_range_stmt) {
        parser.for_range_stmt* frs = (parser.for_range_stmt*)node;
        if (frs.range != (parser.expr_node*)0) { ana_expr(frs.range, ctx); }
        ctx.scope.push_scope();
        if (frs.var_name != (i8*)0) {
            ctx.scope.declare(frs.var_name, sym_var, (i8*)0);
        }
        bool outer_in_loop_r = ctx.in_loop;
        ctx.in_loop = true;
        if (frs.body != (parser.ast_node*)0) { ana_stmt(frs.body, ctx); }
        ctx.in_loop = outer_in_loop_r;
        ctx.scope.pop_scope();
        return;
    }

    if (kind == nd_switch_stmt) {
        parser.switch_stmt* ss = (parser.switch_stmt*)node;
        if (ss.val != (parser.expr_node*)0) { ana_expr(ss.val, ctx); }
        bool outer_in_loop_sw = ctx.in_loop;
        ctx.in_loop = true;  // break is valid inside switch
        i32 ci = 0;
        while (ci < ss.cases_len) {
            if (ss.case_bodies != (parser.block_stmt**)0 && ss.case_bodies[ci] != (parser.block_stmt*)0) {
                ctx.scope.push_scope();
                ana_block(ss.case_bodies[ci], ctx);
                ctx.scope.pop_scope();
            }
            ci = ci + 1;
        }
        ctx.in_loop = outer_in_loop_sw;
        return;
    }

    if (kind == nd_block) {
        ctx.scope.push_scope();
        ana_block((parser.block_stmt*)node, ctx);
        ctx.scope.pop_scope();
        return;
    }

    if (kind == nd_try_expr_stmt) {
        // 'try' is only valid inside a function returning !T (error union)
        if (ctx.in_func && !ctx.cur_func_is_error_union && !ctx.in_generic) {
            i8 msg[256];
            snprintf(msg, (u64)256, "'try' cannot be used in function '%s' which does not return an error union (!T)",
                     ctx.cur_func_name != (i8*)0 ? ctx.cur_func_name : "?");
            ana_error(ctx, (u64)0, msg);
        }
        parser.try_expr_stmt* ts = (parser.try_expr_stmt*)node;
        if (ts.expr != (parser.expr_node*)0) { ana_expr(ts.expr, ctx); }
        return;
    }
}

void ana_block(parser.block_stmt* blk, ana_ctx* ctx) {
    if (blk == (parser.block_stmt*)0) { return; }
    i32 i = 0;
    while (i < blk.stmts_len) {
        if (blk.stmts != (parser.ast_node**)0) { ana_stmt(blk.stmts[i], ctx); }
        i = i + 1;
    }
}

// ---- Function analysis ----

void ana_func(parser.func_decl* fd, ana_ctx* ctx) {
    if (fd == (parser.func_decl*)0 || !fd.has_body) { return; }

    bool outer_in_func           = ctx.in_func;
    i8*  outer_func_name         = ctx.cur_func_name;
    bool outer_func_void         = ctx.cur_func_is_void;
    bool outer_func_eu           = ctx.cur_func_is_error_union;
    bool outer_func_memstr       = ctx.cur_func_has_memstr_param;
    bool outer_func_is_main      = ctx.cur_func_is_main;
    bool outer_in_istruc         = ctx.cur_func_in_istruc;
    bool outer_in_memstr_istruc  = ctx.cur_func_in_memstr_istruc;
    bool outer_generic           = ctx.in_generic;
    if (fd.type_params_len > 0) { ctx.in_generic = true; }

    ctx.in_func         = true;
    ctx.cur_func_name   = fd.name;
    bool is_main_func = (fd.name != (i8*)0 && strcmp(fd.name, "main") == 0);
    ctx.cur_func_is_main = is_main_func;

    bool is_void = (fd.ret_type == (parser.type_node*)0);
    if (!is_void && fd.ret_type.is_primitive && fd.ret_type.prim == (i32)void_t) { is_void = true; }
    ctx.cur_func_is_void = is_void;
    ctx.cur_func_is_error_union = fd.is_error_union;

    // Check if any param is &memstr
    bool has_memstr = false;
    i32 mpi = 0;
    while (mpi < fd.params_len) {
        if (fd.params != (parser.param_decl*)0) {
            parser.type_node* ptype = fd.params[mpi].type;
            if (ptype != (parser.type_node*)0 && ptype.is_memstr_ref) { has_memstr = true; }
        }
        mpi = mpi + 1;
    }
    ctx.cur_func_has_memstr_param = has_memstr;

    ctx.scope.push_scope();

    // Declare implicit `self` for istruc methods that don't use an explicit self pointer as first param
    if (ctx.cur_func_in_istruc) {
        bool has_explicit_self = false;
        if (fd.params_len > 0 && fd.params != (parser.param_decl*)0) {
            parser.type_node* fp = fd.params[0].type;
            // Explicit self: first param is a pointer to a named (non-primitive) type
            if (fp != (parser.type_node*)0 && fp.pointer_depth > 0 && !fp.is_primitive && fp.name != (i8*)0) {
                has_explicit_self = true;
            }
        }
        if (!has_explicit_self) {
            ctx.scope.declare("self", (i32)sym_var, (i8*)0);
        }
    }

    // Register generic type params so they're found as valid identifiers inside the body
    if (fd.type_params_len > 0) {
        i32 tpi = 0;
        while (tpi < fd.type_params_len) {
            if (fd.type_params != (i8**)0 && fd.type_params[tpi] != (i8*)0) {
                ctx.scope.declare(fd.type_params[tpi], (i32)sym_type, (i8*)0);
            }
            tpi = tpi + 1;
        }
    }

    // Register parameters
    i32 pi = 0;
    while (pi < fd.params_len) {
        if (fd.params != (parser.param_decl*)0 && fd.params[pi].name != (i8*)0) {
            bool param_is_fptr = (fd.params[pi].type != (parser.type_node*)0 && fd.params[pi].type.is_func_ptr);
            i32 param_kind = param_is_fptr ? (i32)sym_func_ptr : (i32)sym_var;
            ctx.scope.declare(fd.params[pi].name, param_kind, (i8*)0);
        }
        pi = pi + 1;
    }

    if (fd.body != (i8*)0) {
        ana_block((parser.block_stmt*)fd.body, ctx);
    }

    ctx.scope.pop_scope();

    ctx.in_func                     = outer_in_func;
    ctx.cur_func_name               = outer_func_name;
    ctx.cur_func_is_void            = outer_func_void;
    ctx.cur_func_is_error_union     = outer_func_eu;
    ctx.cur_func_has_memstr_param   = outer_func_memstr;
    ctx.cur_func_is_main            = outer_func_is_main;
    ctx.cur_func_in_istruc          = outer_in_istruc;
    ctx.cur_func_in_memstr_istruc   = outer_in_memstr_istruc;
    ctx.in_generic                  = outer_generic;
}

// ---- Top-level collection ----

void collect_toplevel(parser.ast_node* node, ana_ctx* ctx) {
    if (node == (parser.ast_node*)0) { return; }
    i32 kind = node.kind;

    if (kind == nd_func_decl) {
        parser.func_decl* fd = (parser.func_decl*)node;
        if (fd.name != (i8*)0) {
            bool fd_is_void = (fd.ret_type == (parser.type_node*)0) ||
                              (fd.ret_type.is_primitive && fd.ret_type.prim == (i32)void_t);
            if (fd.has_body) {
                // Check if a prior DEFINITION (has_body) exists; prototype+definition is OK
                i8* prior = ctx.scope.lookup(fd.name);
                bool prior_has_body = false;
                if (prior != (i8*)0) {
                    parser.func_decl* prior_fd = (parser.func_decl*)prior;
                    prior_has_body = prior_fd.has_body;
                }
                if (prior_has_body) {
                    i8 msg[256];
                    snprintf(msg, (u64)256, "duplicate definition of function '%s'", fd.name);
                    ana_error(ctx, fd.line, msg);
                } else {
                    ctx.scope.declare_func_v(fd.name, (i8*)fd, fd.params_len, fd.is_variadic, fd_is_void);
                }
            } else if (!ctx.scope.exists(fd.name)) {
                ctx.scope.declare_func_v(fd.name, (i8*)fd, fd.params_len, fd.is_variadic, fd_is_void);
            }
        }
        return;
    }
    if (kind == nd_var_decl) {
        parser.var_decl* vd = (parser.var_decl*)node;
        if (vd.name != (i8*)0) {
            bool is_fptr = (vd.type != (parser.type_node*)0 && vd.type.is_func_ptr);
            i32 var_kind = is_fptr ? (i32)sym_func_ptr : (i32)sym_var;
            ctx.scope.declare(vd.name, var_kind, (i8*)0);
        }
        return;
    }
    if (kind == nd_enum_decl) {
        parser.enum_decl* ed = (parser.enum_decl*)node;
        // Register enum name — error on redeclaration
        if (ed.name != (i8*)0) {
            if (ctx.scope.exists(ed.name)) {
                i8 msg[256];
                snprintf(msg, (u64)256, "redeclaration of enum '%s'", ed.name);
                ana_error(ctx, ed.line, msg);
            } else {
                ctx.scope.declare(ed.name, sym_enum, (i8*)0);
            }
        }
        // Register all variant/constant names
        i32 vi = 0;
        while (vi < ed.variants_len) {
            if (ed.variant_names != (i8**)0 && ed.variant_names[vi] != (i8*)0) {
                i8* vname = ed.variant_names[vi];
                if (!ctx.scope.exists(vname)) {
                    ctx.scope.declare(vname, sym_var, (i8*)0);
                }
            }
            vi = vi + 1;
        }
        return;
    }
    if (kind == nd_typedef_decl) {
        parser.typedef_decl* td = (parser.typedef_decl*)node;
        if (td.name != (i8*)0 && !ctx.scope.exists(td.name)) {
            ctx.scope.declare(td.name, sym_type, (i8*)0);
        }
        return;
    }
    if (kind == nd_extern_c_block) {
        parser.extern_c_block* ecb = (parser.extern_c_block*)node;
        i32 ei = 0;
        while (ei < ecb.decls_len) {
            if (ecb.decls != (parser.ast_node**)0) { collect_toplevel(ecb.decls[ei], ctx); }
            ei = ei + 1;
        }
        return;
    }
    if (kind == nd_struct_decl) {
        parser.struct_decl* sd = (parser.struct_decl*)node;
        if (sd.name != (i8*)0) {
            if (ctx.scope.lookup_struct(sd.name) != (i8*)0) {
                i8 msg[256];
                snprintf(msg, (u64)256, "duplicate struct declaration '%s'", sd.name);
                ana_error(ctx, sd.line, msg);
            } else {
                ctx.scope.declare_struct(sd.name, node);
            }
        }
        return;
    }
    if (kind == nd_namespace_decl) {
        parser.namespace_decl* nd = (parser.namespace_decl*)node;
        // Generic class: register the name only, skip child analysis until monomorphization.
        // For generic enums, also register variant names so bare usage passes analysis.
        if (nd.type_params_len > 0) {
            if (!ctx.scope.exists(nd.name)) {
                ctx.scope.declare(nd.name, sym_type, (i8*)nd);
            }
            i32 ci = 0;
            while (ci < nd.decls_len) {
                parser.ast_node* gc = (nd.decls != (parser.ast_node**)0) ? nd.decls[ci] : (parser.ast_node*)0;
                if (gc != (parser.ast_node*)0 && gc.kind == nd_enum_decl) {
                    parser.enum_decl* ged2 = (parser.enum_decl*)gc;
                    i32 gvi = 0;
                    while (gvi < ged2.variants_len) {
                        i8* gvname = (ged2.variant_names != (i8**)0) ? ged2.variant_names[gvi] : (i8*)0;
                        if (gvname != (i8*)0 && !ctx.scope.exists(gvname)) {
                            ctx.scope.declare(gvname, sym_var, (i8*)0);
                        }
                        gvi = gvi + 1;
                    }
                }
                ci = ci + 1;
            }
            return;
        }
        // Check derive attributes for unknown traits
        if (nd.attributes != (parser.proc_attr*)0) {
            i32 ai2 = 0;
            while (ai2 < nd.attributes_len) {
                parser.proc_attr pattr_val = nd.attributes[ai2];
                if (pattr_val.name != (i8*)0 && strcmp(pattr_val.name, "derive") == 0) {
                    i32 darg = 0;
                    while (darg < pattr_val.args_len) {
                        i8* trait_name = (pattr_val.args != (i8**)0) ? pattr_val.args[darg] : (i8*)0;
                        if (trait_name != (i8*)0) {
                            bool known = false;
                            if (strcmp(trait_name, "Debug") == 0)   { known = true; }
                            if (strcmp(trait_name, "Clone") == 0)   { known = true; }
                            if (strcmp(trait_name, "Default") == 0) { known = true; }
                            if (strcmp(trait_name, "PartialEq") == 0) { known = true; }
                            if (strcmp(trait_name, "Eq") == 0)      { known = true; }
                            if (strcmp(trait_name, "Hash") == 0)    { known = true; }
                            if (!known) {
                                i8 msg[256];
                                snprintf(msg, (u64)256, "unknown derive macro '%s'", trait_name);
                                ana_error(ctx, nd.line, msg);
                            }
                        }
                        darg = darg + 1;
                    }
                }
                ai2 = ai2 + 1;
            }
        }
        if (nd.name != (i8*)0) {
            if (nd.is_istruc) {
                // istruc/interface: redeclaration is an error
                if (ctx.scope.exists(nd.name) || ctx.scope.lookup_struct(nd.name) != (i8*)0) {
                    i8 msg[256];
                    snprintf(msg, (u64)256, "redeclaration of '%s'", nd.name);
                    ana_error(ctx, nd.line, msg);
                } else {
                    ctx.scope.declare(nd.name, sym_type, (i8*)nd);
                }
                // Check base classes/interfaces
                i32 bi = 0;
                while (bi < nd.bases_len) {
                    i8* bname = (nd.bases != (i8**)0) ? nd.bases[bi] : (i8*)0;
                    if (bname != (i8*)0) {
                        // Check that base type is known
                        if (!ctx.scope.exists(bname) && ctx.scope.lookup_struct(bname) == (i8*)0) {
                            i8 msg[256];
                            snprintf(msg, (u64)256, "unknown base type '%s'", bname);
                            ana_error(ctx, nd.line, msg);
                        } else if (!nd.is_interface) {
                            // Non-interface istruc: check base
                            i8* base_ptr = ctx.scope.lookup(bname);
                            if (base_ptr != (i8*)0 && base_ptr != (i8*)1) {
                                parser.namespace_decl* base_nd = (parser.namespace_decl*)base_ptr;
                                if (base_nd.is_istruc && !base_nd.is_interface) {
                                    i8 msg[256];
                                    snprintf(msg, (u64)256, "cannot inherit from '%s': class inheritance is not supported", bname);
                                    ana_error(ctx, nd.line, msg);
                                } else if (base_nd.is_interface) {
                                    // Check that this istruc implements all required methods from the interface
                                    i32 ifm = 0;
                                    while (ifm < base_nd.decls_len) {
                                        parser.ast_node* ifdecl = (base_nd.decls != (parser.ast_node**)0) ? base_nd.decls[ifm] : (parser.ast_node*)0;
                                        if (ifdecl != (parser.ast_node*)0 && ifdecl.kind == nd_func_decl) {
                                            parser.func_decl* ifd = (parser.func_decl*)ifdecl;
                                            if (ifd.name != (i8*)0 && !ifd.has_body) {
                                                // Required method (no body = abstract)
                                                bool found_impl = false;
                                                i32 mi = 0;
                                                while (mi < nd.decls_len) {
                                                    parser.ast_node* mdecl = (nd.decls != (parser.ast_node**)0) ? nd.decls[mi] : (parser.ast_node*)0;
                                                    if (mdecl != (parser.ast_node*)0 && mdecl.kind == nd_func_decl) {
                                                        parser.func_decl* mfd = (parser.func_decl*)mdecl;
                                                        if (mfd.name != (i8*)0 && strcmp(mfd.name, ifd.name) == 0) {
                                                            found_impl = true;
                                                        }
                                                    }
                                                    mi = mi + 1;
                                                }
                                                if (!found_impl) {
                                                    i8 msg[256];
                                                    snprintf(msg, (u64)256, "'%s' does not implement '%s' required by interface '%s'", nd.name, ifd.name, bname);
                                                    ana_error(ctx, nd.line, msg);
                                                }
                                            }
                                        }
                                        ifm = ifm + 1;
                                    }
                                }
                            }
                        }
                    }
                    bi = bi + 1;
                }
            } else {
                // Real namespace: open — multiple blocks with same name are allowed
                if (!ctx.scope.exists(nd.name)) {
                    ctx.scope.declare(nd.name, sym_type, (i8*)nd);
                }
            }
        }
        // Register methods, static fields, and comptime vars in this namespace;
        // also recurse into nested namespaces.
        // Track method names seen in THIS namespace to detect overloading (not supported).
        i8* local_methods[128];
        i32 local_method_count = 0;
        i32 i = 0;
        while (i < nd.decls_len) {
            parser.ast_node* child = (nd.decls != (parser.ast_node**)0) ? nd.decls[i] : (parser.ast_node*)0;
            if (child != (parser.ast_node*)0 && child.kind == nd_func_decl) {
                parser.func_decl* cfd = (parser.func_decl*)child;
                if (cfd.name != (i8*)0) {
                    if (cfd.has_body && nd.is_istruc) {
                        // Check for duplicate method within this istruc
                        bool is_dup = false;
                        i32 si = 0;
                        while (si < local_method_count) {
                            if (strcmp(local_methods[si], cfd.name) == 0) { is_dup = true; break; }
                            si = si + 1;
                        }
                        if (is_dup) {
                            i8 msg[256];
                            snprintf(msg, (u64)256, "method overloading is not supported: '%s' defined more than once", cfd.name);
                            ana_error(ctx, cfd.line, msg);
                        } else {
                            if (local_method_count < 128) {
                                local_methods[local_method_count] = cfd.name;
                                local_method_count = local_method_count + 1;
                            }
                        }
                    }
                    if (!ctx.scope.exists(cfd.name)) {
                        bool cfd_is_void = (cfd.ret_type == (parser.type_node*)0) ||
                                           (cfd.ret_type.is_primitive && cfd.ret_type.prim == (i32)void_t);
                        ctx.scope.declare_func_v(cfd.name, (i8*)cfd, cfd.params_len, cfd.is_variadic, cfd_is_void);
                    }
                }
            } else if (child != (parser.ast_node*)0 && child.kind == nd_var_decl) {
                parser.var_decl* cvd = (parser.var_decl*)child;
                if (cvd.name != (i8*)0 && !ctx.scope.exists(cvd.name)) {
                    bool cvd_is_fptr = (cvd.type != (parser.type_node*)0 && cvd.type.is_func_ptr);
                    i32 cvd_kind = cvd_is_fptr ? (i32)sym_func_ptr : (i32)sym_var;
                    ctx.scope.declare(cvd.name, cvd_kind, (i8*)0);
                }
            } else if (child != (parser.ast_node*)0 && child.kind == nd_namespace_decl) {
                // Nested namespace: recurse to register its contents too
                collect_toplevel(child, ctx);
            } else if (child != (parser.ast_node*)0 && child.kind == nd_enum_decl) {
                collect_toplevel(child, ctx);
            } else if (child != (parser.ast_node*)0 && child.kind == nd_struct_decl) {
                // Struct/union inside a namespace: register in struct registry
                collect_toplevel(child, ctx);
            }
            i = i + 1;
        }
    }
}

void analyze_bodies(parser.ast_node* node, ana_ctx* ctx) {
    if (node == (parser.ast_node*)0) { return; }
    i32 kind = node.kind;

    if (kind == nd_func_decl) {
        parser.func_decl* fd = (parser.func_decl*)node;
        // Skip type checking for generic functions or functions inside generic namespaces
        if (fd.type_params_len == 0 && !ctx.in_generic) {
            // Check return type
            if (fd.ret_type != (parser.type_node*)0 && !is_type_known(fd.ret_type, ctx)) {
                if (fd.ret_type.name != (i8*)0) {
                    i8 msg[256];
                    snprintf(msg, (u64)256, "unknown return type '%s' in function '%s'", fd.ret_type.name, fd.name);
                    ana_error(ctx, fd.line, msg);
                }
            }
            // Check param types
            i32 pi = 0;
            while (pi < fd.params_len) {
                if (fd.params != (parser.param_decl*)0 && fd.params[pi].type != (parser.type_node*)0) {
                    if (!is_type_known(fd.params[pi].type, ctx)) {
                        if (fd.params[pi].type.name != (i8*)0) {
                            i8 msg[256];
                            snprintf(msg, (u64)256, "unknown param type '%s' in function '%s'", fd.params[pi].type.name, fd.name);
                            ana_error(ctx, fd.params[pi].line, msg);
                        }
                    }
                }
                pi = pi + 1;
            }
        }
        ana_func(fd, ctx);
        return;
    }
    if (kind == nd_namespace_decl) {
        parser.namespace_decl* nd = (parser.namespace_decl*)node;
        bool outer_generic = ctx.in_generic;
        bool outer_in_istruc = ctx.cur_func_in_istruc;
        bool outer_in_memstr_istruc2 = ctx.cur_func_in_memstr_istruc;
        if (nd.is_istruc) { ctx.cur_func_in_istruc = true; }
        if (nd.is_memstr) { ctx.cur_func_in_memstr_istruc = true; }
        bool pushed_tp_scope = false;
        if (nd.type_params_len > 0) {
            ctx.in_generic = true;
            ctx.scope.push_scope();
            pushed_tp_scope = true;
            i32 tpi = 0;
            while (tpi < nd.type_params_len) {
                if (nd.type_params != (i8**)0 && nd.type_params[tpi] != (i8*)0) {
                    ctx.scope.declare(nd.type_params[tpi], (i32)sym_type, (i8*)0);
                }
                tpi = tpi + 1;
            }
        }
        i32 i = 0;
        while (i < nd.decls_len) {
            parser.ast_node* ndchild = (nd.decls != (parser.ast_node**)0) ? nd.decls[i] : (parser.ast_node*)0;
            if (ndchild != (parser.ast_node*)0) {
                // For istruc field var_decls, also check field types (skip in generic context)
                if (ndchild.kind == nd_var_decl && !ctx.in_generic) {
                    parser.var_decl* fvd = (parser.var_decl*)ndchild;
                    if (fvd.type != (parser.type_node*)0 && !is_type_known(fvd.type, ctx)) {
                        if (fvd.type.name != (i8*)0) {
                            i8 msg[256];
                            snprintf(msg, (u64)256, "unknown type '%s' in field '%s'", fvd.type.name, fvd.name);
                            ana_error(ctx, fvd.line, msg);
                        }
                    }
                }
                analyze_bodies(ndchild, ctx);
            }
            i = i + 1;
        }
        if (pushed_tp_scope) { ctx.scope.pop_scope(); }
        ctx.in_generic = outer_generic;
        ctx.cur_func_in_istruc = outer_in_istruc;
        ctx.cur_func_in_memstr_istruc = outer_in_memstr_istruc2;
        return;
    }
    if (kind == nd_struct_decl) {
        parser.struct_decl* sd = (parser.struct_decl*)node;
        // Skip type checking when inside a generic namespace (type params like T are not in scope)
        if (!ctx.in_generic) {
            i32 fi = 0;
            while (fi < sd.fields_len) {
                if (sd.fields != (parser.var_decl**)0 && sd.fields[fi] != (parser.var_decl*)0) {
                    parser.var_decl* f = sd.fields[fi];
                    if (f.type != (parser.type_node*)0 && !is_type_known(f.type, ctx)) {
                        if (f.type.name != (i8*)0) {
                            i8 msg[256];
                            snprintf(msg, (u64)256, "unknown type '%s' in struct field '%s'", f.type.name, f.name);
                            ana_error(ctx, f.line, msg);
                        }
                    }
                }
                fi = fi + 1;
            }
        }
        return;
    }
    if (kind == nd_typedef_decl) {
        parser.typedef_decl* td = (parser.typedef_decl*)node;
        if (!td.is_namespace_using && td.target != (parser.type_node*)0) {
            if (!is_type_known(td.target, ctx)) {
                if (td.target.name != (i8*)0) {
                    i8 msg[256];
                    snprintf(msg, (u64)256, "unknown type '%s' in using/typedef declaration", td.target.name);
                    ana_error(ctx, td.line, msg);
                }
            }
        }
        return;
    }
    if (kind == nd_var_decl) {
        parser.var_decl* vd = (parser.var_decl*)node;
        if (!ctx.in_generic && vd.type != (parser.type_node*)0 && !is_type_known(vd.type, ctx)) {
            if (vd.type.name != (i8*)0) {
                i8 msg[256];
                snprintf(msg, (u64)256, "unknown type '%s'", vd.type.name);
                ana_error(ctx, vd.line, msg);
            }
        }
        if (vd.init != (parser.expr_node*)0) { ana_expr(vd.init, ctx); }
    }
}

// ---- Entry point ----

i32 analyze(parser.program_node* prog) {
    return analyze_unsafe(prog, false);
}

i32 analyze_unsafe(parser.program_node* prog, bool unsafe_mode) {
    if (prog == (parser.program_node*)0) { return 0; }

    ana_ctx ctx;
    ctx.scope.init();
    ctx.error_count               = 0;
    ctx.in_func                   = false;
    ctx.cur_func_name             = (i8*)0;
    ctx.cur_func_is_void          = false;
    ctx.cur_func_is_error_union   = false;
    ctx.cur_func_has_memstr_param = false;
    ctx.cur_func_is_main          = false;
    ctx.cur_func_in_istruc        = false;
    ctx.cur_func_in_memstr_istruc = false;
    ctx.in_loop                   = false;
    ctx.in_generic                = false;
    ctx.is_unsafe                 = unsafe_mode;

    // Pass 1: collect all top-level symbol names
    i32 i = 0;
    while (i < prog.decls_len) {
        if (prog.decls != (parser.ast_node**)0) { collect_toplevel(prog.decls[i], &ctx); }
        i = i + 1;
    }

    // Pass 2: analyze function bodies and global initializers
    i32 j = 0;
    while (j < prog.decls_len) {
        if (prog.decls != (parser.ast_node**)0) { analyze_bodies(prog.decls[j], &ctx); }
        j = j + 1;
    }

    return ctx.error_count;
}

} // namespace analysis
