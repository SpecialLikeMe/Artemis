// Semantic analysis pass for the Artemis self-hosting compiler.
// Performs:
//   1. Two-pass symbol collection (top-level names before body analysis)
//   2. Duplicate local declaration detection
//   3. Basic undefined-identifier warning (soft — IR layer resolves many names)
//   4. Walk of all expressions and statements for future analysis hooks

namespace analysis {

// ---- Analysis context ----

struct ana_ctx {
    let scope: scope_manager;
    let error_count: i32;
    let in_func: bool;
    let cur_func_name: *i8;
    let cur_func_is_void: bool;
    let cur_func_is_error_union: bool;  // true if current function returns !T
    let cur_func_has_memstr_param: bool; // true if current function has &memstr param
    let cur_func_is_main: bool;         // true if current function is main()
    let cur_func_in_istruc: bool;       // true if current function is a method of an istruc
    let cur_func_in_memstr_istruc: bool; // true if current function is inside a memstr-declared type
    let cur_func_is_unsafe: bool;        // true if current function is declared @unsafe
    let in_loop: bool;
    let in_generic: bool;  // inside a generic namespace/struct — skip type param checking
    let is_unsafe: bool;   // true when compiled with --unsafe flag
    // Enum declarations by name, for match exhaustiveness checking. Kept separate
    // from the scope table because the scope's type_ptr slot is read as a var_decl*
    // by other checks.
    let enum_names: [256]*i8;
    let enum_decls: [256]*parser.enum_decl;
    let enum_count: i32;
    let unsafe_depth: i32;  // nesting depth of enclosing `@unsafe { ... }` blocks
}

fn ana_enum_reg(ctx: *ana_ctx, name: *i8, ed: *parser.enum_decl) void {
    if (name == (i8*)0 || ed == (parser.enum_decl*)0 || ctx.enum_count >= 256) { return; }
    let mut i: i32= 0;
    while (i < ctx.enum_count) {
        if (strcmp(ctx.enum_names[i], name) == 0) { ctx.enum_decls[i] = ed; return; }
        i = i + 1;
    }
    ctx.enum_names[ctx.enum_count] = name;
    ctx.enum_decls[ctx.enum_count] = ed;
    ctx.enum_count = ctx.enum_count + 1;
}

fn ana_enum_find(ctx: *ana_ctx, name: *i8) *parser.enum_decl {
    if (name == (i8*)0) { return (parser.enum_decl*)0; }
    let mut i: i32= 0;
    while (i < ctx.enum_count) {
        if (strcmp(ctx.enum_names[i], name) == 0) { return ctx.enum_decls[i]; }
        i = i + 1;
    }
    return (parser.enum_decl*)0;
}

fn ana_error(ctx: *ana_ctx, line: u64, msg: *i8) void {
    aprint("semantic error at line %d: %s\n", .{ (i32)line, msg });
    ctx.error_count = ctx.error_count + 1;
}

// ---- Forward declarations ----
fn ana_stmt(node: *parser.ast_node, ctx: *ana_ctx) void;
fn ana_expr(e: *parser.expr_node, ctx: *ana_ctx) void;
fn ana_block(blk: *parser.block_stmt, ctx: *ana_ctx) void;
fn analyze_unsafe(prog: *parser.program_node, unsafe_mode: bool) i32;

// True when `name` denotes a type (struct/istruc/union/enum/interface) rather than a
// value. Used to recognise a user-defined type passed as a comptime type argument:
// primitives lex into ek_cstype, but a user type arrives as a plain identifier.
fn ana_names_a_type(ctx: *ana_ctx, name: *i8) bool {
    if (name == (i8*)0) { return false; }
    // Plain `struct` declarations live in their own table, not the symbol table.
    if (ctx.scope.lookup_struct(name) != (i8*)0) { return true; }
    let mut k: i32= ctx.scope.lookup_kind(name);
    return k == (i32)sym_type || k == (i32)sym_enum;
}

// Register all identifier bindings introduced by a pattern into the current scope.
// Handles pk_binding (name @ sub), pk_ident (plain name), pk_tuple (fields), pk_struct (fields).
fn ana_register_pat_bindings(pat: *parser.pat_node, ctx: *ana_ctx) void {
    if (pat == (parser.pat_node*)0) { return; }
    let mut k: i32= pat.kind;
    // pk_wildcard = 0: no binding
    if (k == 0) { return; }
    // pk_ident = 2: always register as local binding (shadows any global of the same name)
    if (k == 2) {
        if (pat.name != (i8*)0) {
            ctx.scope.declare(pat.name, (i32)sym_pat_bind, (i8*)0);
        }
        return;
    }
    // pk_binding = 3: register name, recurse into sub_pat
    if (k == 3) {
        if (pat.name != (i8*)0) { ctx.scope.declare(pat.name, (i32)sym_pat_bind, (i8*)0); }
        if (pat.sub_pat != (i8*)0) { ana_register_pat_bindings((parser.pat_node*)pat.sub_pat, ctx); }
        return;
    }
    // pk_tuple = 7: recurse into each field's sub-pattern
    if (k == 7) {
        let mut tfi: i32= 0;
        while (tfi < pat.fields_len) {
            let mut pf: *parser.pat_field= &pat.fields[tfi];
            if (pf.name != (i8*)0) { ctx.scope.declare(pf.name, (i32)sym_pat_bind, (i8*)0); }
            if (pf.pat != (i8*)0) { ana_register_pat_bindings((parser.pat_node*)pf.pat, ctx); }
            tfi = tfi + 1;
        }
        return;
    }
    // pk_struct = 6: recurse into each field's sub-pattern
    if (k == 6) {
        let mut sfi2: i32= 0;
        while (sfi2 < pat.fields_len) {
            let mut pf2: *parser.pat_field= &pat.fields[sfi2];
            if (pf2.name != (i8*)0) { ctx.scope.declare(pf2.name, (i32)sym_pat_bind, (i8*)0); }
            if (pf2.pat != (i8*)0) { ana_register_pat_bindings((parser.pat_node*)pf2.pat, ctx); }
            sfi2 = sfi2 + 1;
        }
        return;
    }
}

// ---- Type validity helper ----

fn is_type_known(t: *parser.type_node, ctx: *ana_ctx) bool {
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

fn ana_expr(e: *parser.expr_node, ctx: *ana_ctx) void {
    if (e == (parser.expr_node*)0) { return; }
    let mut kind: i32= e.kind;

    if (kind == ek_identifier) {
        if (e.str_val != (i8*)0 && !ctx.in_generic) {
            // Skip compiler-internal names (e.g. __derive_Debug_Point, __construct__)
            let mut is_internal: bool= (e.str_val[0] == '_' && e.str_val[1] == '_');
            // Skip namespace-mangled names used as type expressions (e.g. sizeof(lexer__NS_token_t))
            let mut is_ns_mangled: bool= (strstr(e.str_val, "__NS_") != (i8*)0);
            // Check in both function bodies and global initializers (pass 1 has collected all top-level names)
            if (!is_internal && !is_ns_mangled && !ctx.scope.exists(e.str_val)) {
                // Also check struct registry (e.g. sizeof(MyStruct) where MyStruct is expr)
                if (ctx.scope.lookup_struct(e.str_val) == (i8*)0) {
                    let mut msg: [256]i8;
                    afmt(msg, (u64)256, "undefined identifier '%s'", .{ e.str_val });
                    ana_error(ctx, e.line, msg);
                }
            }
        }
        return;
    }

    if (kind == ek_call) {
        if (e.callee != (parser.expr_node*)0) { ana_expr(e.callee, ctx); }
        let mut ai: i32= 0;
        while (ai < e.args_len) {
            if (e.args != (parser.expr_node**)0) { ana_expr(e.args[ai], ctx); }
            ai = ai + 1;
        }
        // Check callee for simple identifier callees
        if (e.callee != (parser.expr_node*)0 && e.callee.kind == (i32)ek_identifier &&
            e.callee.str_val != (i8*)0) {
            let mut fname: *i8= e.callee.str_val;
            let mut is_internal: bool= (fname[0] == '_' && fname[1] == '_');
            if (!is_internal) {
                let mut callee_kind: i32= ctx.scope.lookup_kind(fname);
                // sym_func_ptr (=4) is a function pointer variable — callable, skip
                if (callee_kind == (i32)sym_var) {
                    let mut msg: [256]i8;
                    afmt(msg, (u64)256, "'%s' is not callable (declared as a variable)", .{ fname });
                    ana_error(ctx, e.line, msg);
                } else if (callee_kind == (i32)sym_func) {
                    let mut is_var: bool= ctx.scope.lookup_is_variadic(fname);
                    if (!is_var) {
                        let mut expected: i32= ctx.scope.lookup_param_count(fname);
                        // Count ek_cstype (comptime type) args — these are type params,
                        // not value params, so exclude them from the actual arg count.
                        let mut actual_args: i32= e.args_len;
                        let mut ct_ai: i32= 0;
                        while (ct_ai < e.args_len) {
                            let mut cta: *parser.expr_node= e.args[ct_ai];
                            if (cta != (parser.expr_node*)0) {
                                if (cta.kind == (i32)ek_cstype) {
                                    actual_args = actual_args - 1;
                                } else if (cta.kind == (i32)ek_identifier && cta.str_val != (i8*)0 &&
                                           ana_names_a_type(ctx, cta.str_val)) {
                                    // A user-defined type passed as a comptime type argument
                                    // arrives as a plain identifier — only primitives are
                                    // lexed into ek_cstype. Without this, `f(MyStruct)` is
                                    // counted as a value argument and rejected on arity.
                                    actual_args = actual_args - 1;
                                }
                            }
                            ct_ai = ct_ai + 1;
                        }
                        if (expected >= 0 && actual_args != expected) {
                            let mut msg: [256]i8;
                            afmt(msg, (u64)256, "wrong number of arguments to '%s': expected %d, got %d", .{ fname, expected, actual_args });
                            ana_error(ctx, e.line, msg);
                        }
                    }
                    // Enforce allocator discipline: raw heap operations only inside memstr-declared types
                    // or @unsafe-annotated functions.
                    if (!ctx.in_generic && ctx.in_func && !ana_in_unsafe_ctx(ctx)) {
                        let mut is_heap_op: bool= (strcmp(fname, "malloc")  == 0 ||
                                           strcmp(fname, "realloc") == 0 ||
                                           strcmp(fname, "calloc")  == 0 ||
                                           strcmp(fname, "free")    == 0);
                        if (is_heap_op) {
                            let mut msg: [256]i8;
                            afmt(msg, (u64)256, "direct heap operation ('%s') not allowed outside a 'memstr' allocator type", .{ fname });
                            ana_error(ctx, e.line, msg);
                        }
                    }

                    // Calling an @unsafe function requires an unsafe context. The
                    // callee's body is unverifiable, so the obligation to justify the
                    // call sits with the caller — that is what makes the marker mean
                    // something beyond documentation.
                    if (!ctx.in_generic && ctx.in_func && !ana_in_unsafe_ctx(ctx)) {
                        let mut ufd_ptr: *i8= ctx.scope.lookup(fname);
                        if (ufd_ptr != (i8*)0 && ufd_ptr != (i8*)1 && ufd_ptr != (i8*)2 &&
                                ctx.scope.lookup_kind(fname) == (i32)sym_func) {
                            let mut ufd: *parser.func_decl= (parser.func_decl*)ufd_ptr;
                            if (ufd.is_unsafe) {
                                let mut msg: [256]i8;
                                afmt(msg, (u64)256, "call to '@unsafe' function '%s' requires an unsafe context: wrap it in '@unsafe { ... }', or mark the caller '@unsafe fn'", .{ fname });
                                ana_error(ctx, e.line, msg);
                            }
                        }
                    }
                    // Check nullable arg to non-nullable param, and non-memstr arg to &memstr param
                    if (!ctx.in_generic && ctx.in_func) {
                        let mut fd_ptr: *i8= ctx.scope.lookup(fname);
                        if (fd_ptr != (i8*)0 && fd_ptr != (i8*)2) {
                            let mut cfd2: *parser.func_decl= (parser.func_decl*)fd_ptr;
                            let mut nai: i32= 0;
                            while (nai < e.args_len && nai < cfd2.params_len) {
                                let mut arg_e: *parser.expr_node= (e.args != (parser.expr_node**)0) ? e.args[nai] : (parser.expr_node*)0;
                                if (arg_e != (parser.expr_node*)0 && arg_e.kind == (i32)ek_identifier &&
                                    arg_e.str_val != (i8*)0) {
                                    let mut arg_nullable: bool= ctx.scope.lookup_is_nullable(arg_e.str_val);
                                    if (arg_nullable) {
                                        let mut pd: *parser.param_decl= (cfd2.params != (parser.param_decl*)0) ?
                                            &cfd2.params[nai] : (parser.param_decl*)0;
                                        if (pd != (parser.param_decl*)0 && pd.type != (parser.type_node*)0) {
                                            if (!pd.type.is_nullable && pd.type.pointer_depth == 0 && !pd.type.is_func_ptr) {
                                                let mut msg: [256]i8;
                                                afmt(msg, (u64)256, "cannot pass nullable value as non-nullable parameter '%s'", .{ pd.name != (i8*)0 ? pd.name : "?" });
                                                ana_error(ctx, e.line, msg);
                                            }
                                        }
                                    }
                                    // Check non-memstr arg to &memstr param
                                    if (!ctx.is_unsafe && cfd2.params != (parser.param_decl*)0) {
                                        let mut param_nai: parser.param_decl= cfd2.params[nai];
                                        if (param_nai.type != (parser.type_node*)0 && param_nai.type.is_memstr_ref) {
                                            // Arg must be a memstr-type variable
                                            let mut arg_type_ptr: *i8= ctx.scope.lookup(arg_e.str_val);
                                            let mut arg_is_memstr: bool= false;
                                            // Sentinel (i8*)2 = &memstr parameter being passed through
                                            if (arg_type_ptr == (i8*)2) {
                                                arg_is_memstr = true;
                                            } else if (arg_type_ptr != (i8*)0 && arg_type_ptr != (i8*)1) {
                                                let mut arg_vd: *parser.var_decl= (parser.var_decl*)arg_type_ptr;
                                                if (arg_vd.type != (parser.type_node*)0) {
                                                    // Accept if arg is a concrete memstr type in scope
                                                    if (!arg_vd.type.is_primitive && arg_vd.type.name != (i8*)0) {
                                                        let mut arg_type_name: *i8= arg_vd.type.name;
                                                        let mut arg_ns: *i8= ctx.scope.lookup(arg_type_name);
                                                        if (arg_ns != (i8*)0 && arg_ns != (i8*)1) {
                                                            let mut arg_nd: *parser.namespace_decl= (parser.namespace_decl*)arg_ns;
                                                            if (arg_nd.is_memstr) { arg_is_memstr = true; }
                                                        }
                                                    }
                                                }
                                            }
                                            if (!arg_is_memstr) {
                                                let mut msg: [256]i8;
                                                afmt(msg, (u64)256, "argument '%s' is not a 'memstr' allocator (parameter requires '&memstr')", .{ arg_e.str_val });
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
            let mut obj_name: *i8= e.callee.object.str_val;
            let mut meth_name: *i8= e.callee.member_name;
            let mut is_construct_call: bool= (strcmp(meth_name, "__construct__") == 0);
            // __construct__ can only be called on comptime variables
            if (is_construct_call && ctx.scope.lookup_kind(obj_name) == (i32)sym_var) {
                let mut obj_is_comptime: bool= ctx.scope.lookup_is_comptime(obj_name);
                if (!obj_is_comptime) {
                    let mut msg: [256]i8;
                    afmt(msg, (u64)256, "cannot call '__construct__' on '%s': variable was not declared with 'comptime'", .{ obj_name });
                    ana_error(ctx, e.line, msg);
                }
            }
            let mut is_internal_m: bool= (meth_name[0] == '_' && meth_name[1] == '_');
            if (!is_internal_m && ctx.scope.lookup_kind(obj_name) == (i32)sym_var) {
                let mut type_ptr_m: *i8= ctx.scope.lookup(obj_name);
                if (type_ptr_m != (i8*)0 && type_ptr_m != (i8*)1 && type_ptr_m != (i8*)2) {
                    let mut mvd: *parser.var_decl= (parser.var_decl*)type_ptr_m;
                    if (mvd.type != (parser.type_node*)0 && !mvd.type.is_primitive &&
                        mvd.type.name != (i8*)0) {
                        let mut type_name_m: *i8= mvd.type.name;
                        let mut ns_ptr_m: *i8= ctx.scope.lookup(type_name_m);
                        if (ns_ptr_m != (i8*)0 && ns_ptr_m != (i8*)1) {
                            let mut mns: *parser.namespace_decl= (parser.namespace_decl*)ns_ptr_m;
                            // A concrete allocator's receiver is rewritten to memstr's fat
                            // pointer during codegen, so `a.mmap(n)` is checked against
                            // memstr's helper signature, not the raw slot method that the
                            // allocator itself implements.
                            let mut ms_recv: bool= mns.is_memstr &&
                                (strcmp(meth_name, "mmap")    == 0 || strcmp(meth_name, "rsmap")  == 0 ||
                                 strcmp(meth_name, "rmap")    == 0 || strcmp(meth_name, "free")   == 0 ||
                                 strcmp(meth_name, "destroy") == 0 || strcmp(meth_name, "deinit") == 0 ||
                                 strcmp(meth_name, "create")  == 0 || strcmp(meth_name, "create_n") == 0 ||
                                 strcmp(meth_name, "zeroed")  == 0 || strcmp(meth_name, "mmap_aligned") == 0);
                            // Find the method in the namespace and count its non-self params
                            let mut mdi: i32= ms_recv ? mns.decls_len : 0;
                            while (mdi < mns.decls_len) {
                                let mut mdchild: *parser.ast_node= (mns.decls != (parser.ast_node**)0) ? mns.decls[mdi] : (parser.ast_node*)0;
                                if (mdchild != (parser.ast_node*)0 && mdchild.kind == nd_func_decl) {
                                    let mut mfd2: *parser.func_decl= (parser.func_decl*)mdchild;
                                    if (mfd2.name != (i8*)0 && strcmp(mfd2.name, meth_name) == 0) {
                                        if (!mfd2.is_variadic) {
                                            // Detect explicit self: first param is pointer to (or value of) the struct type
                                            let mut first_is_self: bool= false;
                                            if (mfd2.params_len > 0 && mfd2.params != (parser.param_decl*)0) {
                                                let mut fp: *parser.type_node= mfd2.params[0].type;
                                                if (fp != (parser.type_node*)0 &&
                                                    fp.name != (i8*)0 && mns.name != (i8*)0 &&
                                                    strcmp(fp.name, mns.name) == 0) {
                                                    first_is_self = true;  // also works for by-value self
                                                }
                                            }
                                            let mut non_self: i32= first_is_self ? mfd2.params_len - 1 : mfd2.params_len;
                                            // Comptime type arguments are not value params —
                                            // they live in type_params. Exclude them, the same
                                            // way the free-function arity check does.
                                            let mut m_actual: i32= e.args_len;
                                            let mut m_ci: i32= 0;
                                            while (m_ci < e.args_len) {
                                                let mut m_a: *parser.expr_node= e.args[m_ci];
                                                if (m_a != (parser.expr_node*)0) {
                                                    if (m_a.kind == (i32)ek_cstype) { m_actual = m_actual - 1; }
                                                    else if (m_a.kind == (i32)ek_identifier && m_a.str_val != (i8*)0 &&
                                                             ana_names_a_type(ctx, m_a.str_val)) { m_actual = m_actual - 1; }
                                                }
                                                m_ci = m_ci + 1;
                                            }
                                            if (m_actual != non_self) {
                                                let mut msg: [256]i8;
                                                afmt(msg, (u64)256, "wrong number of arguments to method '%s': expected %d, got %d", .{ meth_name, non_self, m_actual });
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
                let mut msg: [256]i8;
                afmt(msg, (u64)256, "unknown type '%s' in sizeof", .{ e.cast_type.name });
                ana_error(ctx, e.line, msg);
            }
        }
        if (e.operand != (parser.expr_node*)0) { ana_expr(e.operand, ctx); }
        return;
    }

    if (kind == ek_assign) {
        // Immutability check: cannot assign to an immutable variable
        if (!ctx.in_generic && e.lhs != (parser.expr_node*)0 && e.lhs.kind == (i32)ek_identifier &&
            e.lhs.str_val != (i8*)0) {
            let mut asgn_name: *i8= e.lhs.str_val;
            if (ctx.scope.lookup_kind(asgn_name) == (i32)sym_var) {
                let mut vd_ptr: *i8= ctx.scope.lookup(asgn_name);
                if (vd_ptr != (i8*)0 && vd_ptr != (i8*)1 && vd_ptr != (i8*)2) {
                    let mut asgn_vd: *parser.var_decl= (parser.var_decl*)vd_ptr;
                    if (!asgn_vd.is_mutable && !asgn_vd.is_constexpr) {
                        let mut msg: [256]i8;
                        afmt(msg, (u64)256, "cannot assign to immutable variable '%s' (declare with 'let mut')", .{ asgn_name });
                        ana_error(ctx, e.line, msg);
                    }
                }
            }
        }
        ana_expr(e.lhs, ctx);
        ana_expr(e.rhs, ctx);
        return;
    }

    if (kind == ek_binary) {
        // Compound assignment immutability check (+=, -=, etc.)
        if (!ctx.in_generic && e.lhs != (parser.expr_node*)0 && e.lhs.kind == (i32)ek_identifier &&
            e.lhs.str_val != (i8*)0 &&
            (e.bop == (i32)bop_add_assign || e.bop == (i32)bop_sub_assign ||
             e.bop == (i32)bop_mul_assign || e.bop == (i32)bop_div_assign ||
             e.bop == (i32)bop_mod_assign || e.bop == (i32)bop_and_assign ||
             e.bop == (i32)bop_or_assign  || e.bop == (i32)bop_xor_assign ||
             e.bop == (i32)bop_shl_assign || e.bop == (i32)bop_shr_assign)) {
            let mut cmp_name: *i8= e.lhs.str_val;
            if (ctx.scope.lookup_kind(cmp_name) == (i32)sym_var) {
                let mut vd_ptr2: *i8= ctx.scope.lookup(cmp_name);
                if (vd_ptr2 != (i8*)0 && vd_ptr2 != (i8*)1 && vd_ptr2 != (i8*)2) {
                    let mut cmp_vd: *parser.var_decl= (parser.var_decl*)vd_ptr2;
                    if (!cmp_vd.is_mutable && !cmp_vd.is_constexpr) {
                        let mut msg2: [256]i8;
                        afmt(msg2, (u64)256, "cannot assign to immutable variable '%s' (declare with 'let mut')", .{ cmp_name });
                        ana_error(ctx, e.line, msg2);
                    }
                }
            }
        }
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
            let mut op_name: *i8= e.operand.str_val;
            if (ctx.scope.lookup_kind(op_name) == (i32)sym_var) {
                let mut type_ptr2: *i8= ctx.scope.lookup(op_name);
                if (type_ptr2 != (i8*)0 && type_ptr2 != (i8*)1 && type_ptr2 != (i8*)2) {
                    let mut dvd: *parser.var_decl= (parser.var_decl*)type_ptr2;
                    // Only error for primitives (typedef aliases may resolve to pointer types)
                    if (dvd.type != (parser.type_node*)0 && dvd.type.pointer_depth == 0 &&
                        !dvd.type.is_func_ptr && dvd.type.is_primitive) {
                        let mut msg: [256]i8;
                        afmt(msg, (u64)256, "cannot dereference non-pointer variable '%s'", .{ op_name });
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
        // Check: member access on a nullable ?T without explicit unwrap
        if (ctx.in_func && !ctx.in_generic && e.object != (parser.expr_node*)0 &&
            e.object.kind == (i32)ek_identifier && e.object.str_val != (i8*)0) {
            let mut obj_is_nullable: bool= ctx.scope.lookup_is_nullable(e.object.str_val);
            if (obj_is_nullable) {
                let mut msg: [256]i8;
                afmt(msg, (u64)256, "member access on nullable value '%s' — unwrap it first (e.g., '!%s' or null-check)", .{ e.object.str_val, e.object.str_val });
                ana_error(ctx, e.line, msg);
            }
        }
        // Check: member access on a void-returning function call
        if (ctx.in_func && !ctx.in_generic && e.object != (parser.expr_node*)0 &&
            e.object.kind == (i32)ek_call) {
            let mut callee_e: *parser.expr_node= e.object.callee;
            if (callee_e != (parser.expr_node*)0 && callee_e.kind == (i32)ek_identifier &&
                callee_e.str_val != (i8*)0) {
                if (ctx.scope.lookup_is_void_ret(callee_e.str_val)) {
                    let mut msg: [256]i8;
                    afmt(msg, (u64)256, "member access on void return type (function '%s' returns void)", .{ callee_e.str_val });
                    ana_error(ctx, e.line, msg);
                }
            }
        }
        // Type check: member access on a known type
        if (ctx.in_func && !ctx.in_generic && e.object != (parser.expr_node*)0 &&
            e.member_name != (i8*)0 && e.object.kind == (i32)ek_identifier &&
            e.object.str_val != (i8*)0) {
            let mut obj_name: *i8= e.object.str_val;
            let mut is_internal: bool= (obj_name[0] == '_' && obj_name[1] == '_');
            if (!is_internal && ctx.scope.lookup_kind(obj_name) == (i32)sym_var) {
                let mut type_ptr: *i8= ctx.scope.lookup(obj_name);
                // type_ptr == (i8*)vd for local vars — check if it looks like a valid pointer
                if (type_ptr != (i8*)0 && type_ptr != (i8*)1 && type_ptr != (i8*)2) {
                    let mut vd: *parser.var_decl= (parser.var_decl*)type_ptr;
                    if (vd.type != (parser.type_node*)0) {
                        // Primitive type: no members (except complex/rational which have .re/.im/.num/.den)
                        let mut prim_val: i32= vd.type.prim;
                        let mut is_compound_prim: bool= (prim_val == 6 || prim_val == 7); // arb_rational=6, arb_complex=7
                        if (vd.type.is_primitive && vd.type.pointer_depth == 0 && !vd.type.is_func_ptr && !is_compound_prim) {
                            let mut msg: [256]i8;
                            afmt(msg, (u64)256, "member access on primitive type (no members)", .{});
                            ana_error(ctx, e.line, msg);
                        } else if (!vd.type.is_primitive && vd.type.name != (i8*)0) {
                            // Named type: check if member exists
                            let mut type_name: *i8= vd.type.name;
                            let mut member_found: bool= false;
                            // Check as namespace_decl (istruc)
                            let mut ns_ptr: *i8= ctx.scope.lookup(type_name);
                            if (ns_ptr != (i8*)0 && ns_ptr != (i8*)1) {
                                let mut mnd: *parser.namespace_decl= (parser.namespace_decl*)ns_ptr;
                                // Check struct_decl child (first child) for fields
                                let mut di: i32= 0;
                                while (di < mnd.decls_len && !member_found) {
                                    let mut dchild: *parser.ast_node= (mnd.decls != (parser.ast_node**)0) ? mnd.decls[di] : (parser.ast_node*)0;
                                    if (dchild != (parser.ast_node*)0) {
                                        if (dchild.kind == nd_struct_decl) {
                                            let mut fsd: *parser.struct_decl= (parser.struct_decl*)dchild;
                                            let mut fi: i32= 0;
                                            while (fi < fsd.fields_len && !member_found) {
                                                let mut flds: **parser.var_decl= fsd.fields;
                                                let mut fld: *parser.var_decl= (flds != (parser.var_decl**)0) ? flds[fi] : (parser.var_decl*)0;
                                                if (fld != (parser.var_decl*)0 && fld.name != (i8*)0) {
                                                    if (strcmp(fld.name, e.member_name) == 0) { member_found = true; }
                                                }
                                                fi = fi + 1;
                                            }
                                        } else if (dchild.kind == nd_func_decl) {
                                            let mut mfd: *parser.func_decl= (parser.func_decl*)dchild;
                                            if (mfd.name != (i8*)0 && strcmp(mfd.name, e.member_name) == 0) {
                                                member_found = true;
                                            }
                                        }
                                    }
                                    di = di + 1;
                                }
                            }
                            // Check as struct in struct registry
                            let mut sd_ptr: *i8= ctx.scope.lookup_struct(type_name);
                            if (!member_found && sd_ptr != (i8*)0) {
                                let mut sd: *parser.struct_decl= (parser.struct_decl*)sd_ptr;
                                if (sd.kind == nd_struct_decl) {
                                    let mut fi: i32= 0;
                                    while (fi < sd.fields_len && !member_found) {
                                        let mut sflds: **parser.var_decl= sd.fields;
                                        let mut sfld: *parser.var_decl= (sflds != (parser.var_decl**)0) ? sflds[fi] : (parser.var_decl*)0;
                                        if (sfld != (parser.var_decl*)0 && sfld.name != (i8*)0) {
                                            if (strcmp(sfld.name, e.member_name) == 0) { member_found = true; }
                                        }
                                        fi = fi + 1;
                                    }
                                }
                            }
                            if (!member_found && ns_ptr != (i8*)0 && ns_ptr != (i8*)1) {
                                // Known istruc type but member not found
                                let mut msg: [256]i8;
                                afmt(msg, (u64)256, "no member '%s' in type '%s'", .{ e.member_name, type_name });
                                ana_error(ctx, e.line, msg);
                            } else if (!member_found && sd_ptr != (i8*)0) {
                                let mut msg: [256]i8;
                                afmt(msg, (u64)256, "no field '%s' in struct/union '%s'", .{ e.member_name, type_name });
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
    if (kind == ek_cast_as)   { ana_expr(e.operand, ctx); return; }
    if (kind == ek_match_expr) { return; }

    if (kind == ek_null_coal) {
        ana_expr(e.lhs, ctx);
        ana_expr(e.rhs, ctx);
        return;
    }

    if (kind == ek_lambda) {
        ctx.scope.push_scope();
        // Register captures and parameters so their uses inside the body aren't flagged
        let mut ci: i32= 0;
        while (ci < e.lambda_cap_len) {
            if (e.lambda_cap_names != (i8**)0 && e.lambda_cap_names[ci] != (i8*)0) {
                ctx.scope.declare(e.lambda_cap_names[ci], sym_var, (i8*)0);
            }
            ci = ci + 1;
        }
        let mut lpi: i32= 0;
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
            let mut msg: [256]i8;
            afmt(msg, (u64)256, "'try' cannot be used in function '%s' which does not return an error union (!T)", .{ ctx.cur_func_name != (i8*)0 ? ctx.cur_func_name : "?" });
            ana_error(ctx, e.line, msg);
        }
        if (e.operand != (parser.expr_node*)0) { ana_expr(e.operand, ctx); }
        return;
    }
}

// ---- Statement analysis ----

fn ana_stmt(node: *parser.ast_node, ctx: *ana_ctx) void {
    if (node == (parser.ast_node*)0) { return; }
    let mut kind: i32= node.kind;

    if (kind == nd_var_decl) {
        let mut vd: *parser.var_decl= (parser.var_decl*)node;
        // comptime var cannot have constructor args at declaration site
        if (vd.is_constexpr && vd.has_ctor_parens && vd.ctor_args_len > 0 && !ctx.in_generic) {
            let mut msg: [256]i8;
            afmt(msg, (u64)256, "'comptime' variable '%s' cannot have constructor arguments at declaration", .{ vd.name != (i8*)0 ? vd.name : "?" });
            ana_error(ctx, vd.line, msg);
        }
        // Validate float bit widths (must be IEEE-defined: 16, 32, 64, 80, 128)
        if (!ctx.in_generic && vd.type != (parser.type_node*)0 && vd.type.is_primitive && vd.type.has_prim &&
                (vd.type.prim == (i32)arb_float || vd.type.prim == (i32)arb_real)) {
            let mut fw: i32= vd.type.bit_width;
            let mut valid_fw: bool= (fw == 0 || fw == 16 || fw == 32 || fw == 64 || fw == 80 || fw == 128);
            if (!valid_fw) {
                let mut msg: [256]i8;
                afmt(msg, (u64)256, "invalid float bit width %d: valid widths are 16, 32, 64, 80, 128", .{ fw });
                ana_error(ctx, vd.line, msg);
            }
        }
        // Check the declared type is known (skip in generic context)
        if (!ctx.in_generic && vd.type != (parser.type_node*)0 && !is_type_known(vd.type, ctx)) {
            if (vd.type.name != (i8*)0) {
                let mut msg: [256]i8;
                afmt(msg, (u64)256, "unknown type '%s'", .{ vd.type.name });
                ana_error(ctx, vd.line, msg);
            }
        }
        if (vd.name != (i8*)0) {
            // Duplicate local check within the same scope depth only
            if (ctx.in_func) {
                let mut dup: bool= ctx.scope.lookup_at_depth(vd.name);
                if (dup) {
                    let mut msg: [256]i8;
                    afmt(msg, (u64)256, "duplicate declaration of '%s' in same scope", .{ vd.name });
                    ana_error(ctx, vd.line, msg);
                } else {
                    // Declare as sym_func_ptr if the type is a function pointer or init is lambda
                    let mut is_fptr: bool= (vd.type != (parser.type_node*)0 && vd.type.is_func_ptr);
                    let mut is_lambda_init: bool= (vd.init != (parser.expr_node*)0 && vd.init.kind == (i32)ek_lambda);
                    let mut var_kind: i32= (is_fptr || is_lambda_init) ? (i32)sym_func_ptr : (i32)sym_var;
                    let mut var_nullable: bool= (vd.type != (parser.type_node*)0 && vd.type.is_nullable);
                    ctx.scope.declare_var_comptime(vd.name, var_kind, (i8*)vd, var_nullable, vd.is_constexpr);
                }
            }
        }
        // Check: nullable variable assigned to a non-nullable, non-pointer, non-auto local
        if (vd.init != (parser.expr_node*)0 && vd.init.kind == (i32)ek_identifier &&
            vd.init.str_val != (i8*)0 && vd.type != (parser.type_node*)0 &&
            !vd.type.is_nullable && !vd.type.is_auto && !ctx.in_generic) {
            let mut init_is_nullable: bool= ctx.scope.lookup_is_nullable(vd.init.str_val);
            if (init_is_nullable) {
                let mut msg: [256]i8;
                if (vd.name != (i8*)0) {
                    afmt(msg, (u64)256, "cannot assign nullable value to non-nullable variable '%s'", .{ vd.name });
                } else {
                    afmt(msg, (u64)256, "cannot assign nullable value to non-nullable type", .{});
                }
                ana_error(ctx, vd.line, msg);
            }
        }
        // Check: null assigned to a non-pointer, non-nullable type
        if (vd.init != (parser.expr_node*)0 && vd.init.kind == (i32)ek_null_lit &&
            vd.type != (parser.type_node*)0 && !ctx.in_generic) {
            let mut is_ptr: bool= (vd.type.pointer_depth > 0 || vd.type.is_func_ptr);
            let mut is_nullable: bool= vd.type.is_nullable;
            let mut is_auto: bool= vd.type.is_auto;
            if (!is_ptr && !is_nullable && !is_auto) {
                let mut msg: [256]i8;
                if (vd.name != (i8*)0) {
                    afmt(msg, (u64)256, "cannot assign null to non-pointer variable '%s'", .{ vd.name });
                } else {
                    afmt(msg, (u64)256, "cannot assign null to non-pointer type", .{});
                }
                ana_error(ctx, vd.line, msg);
            }
        }
        // Float literal assigned to an integer type is a type error
        if (!ctx.in_generic && vd.init != (parser.expr_node*)0 &&
            vd.init.kind == (i32)ek_float_lit &&
            vd.type != (parser.type_node*)0 && vd.type.is_primitive && vd.type.has_prim &&
            vd.type.pointer_depth == 0) {
            let mut pi: i32= vd.type.prim;
            let mut is_int_prim: bool= (pi == (i32)arb_int || pi == (i32)arb_uint || pi == (i32)arb_bool ||
                                        pi == (i32)arb_nat  || pi == (i32)arb_usize || pi == (i32)arb_isize ||
                                        pi == (i32)arb_iofs  || pi == (i32)char_t);
            if (is_int_prim) {
                let mut msg: [256]i8;
                afmt(msg, (u64)256, "cannot assign float literal to integer type for variable '%s'", .{ vd.name != (i8*)0 ? vd.name : "?" });
                ana_error(ctx, vd.line, msg);
            }
        }
        // String literal assigned to a non-pointer, non-auto primitive type is a type error
        if (!ctx.in_generic && vd.init != (parser.expr_node*)0 &&
            vd.init.kind == (i32)ek_string_lit &&
            vd.type != (parser.type_node*)0 && vd.type.pointer_depth == 0 &&
            !vd.type.is_auto && vd.type.is_primitive) {
            let mut msg: [256]i8;
            afmt(msg, (u64)256, "cannot assign string literal to non-pointer type for variable '%s'", .{ vd.name != (i8*)0 ? vd.name : "?" });
            ana_error(ctx, vd.line, msg);
        }
        if (vd.init != (parser.expr_node*)0) { ana_expr(vd.init, ctx); }
        return;
    }

    if (kind == nd_expr_stmt) {
        let mut es: *parser.expr_stmt= (parser.expr_stmt*)node;
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
        let mut rs: *parser.return_stmt= (parser.return_stmt*)node;
        if (rs.val != (parser.expr_node*)0) {
            ana_expr(rs.val, ctx);
            // Returning a value from a void function is an error
            if (ctx.cur_func_is_void) {
                aprint("error at line %llu: void function '%s' cannot return a value\n", .{ rs.line, ctx.cur_func_name != (i8*)0 ? ctx.cur_func_name : "?" });
                ctx.error_count = ctx.error_count + 1;
            }
        }
        return;
    }

    if (kind == nd_if_stmt) {
        let mut is: *parser.if_stmt= (parser.if_stmt*)node;
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
            let mut kw: *i8= kind == nd_break_stmt ? "break" : "continue";
            let mut msg: [128]i8;
            afmt(msg, (u64)128, "'%s' used outside a loop", .{ kw });
            ana_error(ctx, node.line, msg);
        }
        return;
    }

    // Inline assembly is opaque to every analysis in the compiler — it can touch any
    // register or address, so SMT reasoning about the surrounding code stops being
    // sound. It belongs behind the same marker as a foreign declaration; requiring it
    // on the enclosing function keeps @unsafe greppable at declaration level.
    if (kind == nd_asm_stmt) {
        if (!ana_in_unsafe_ctx(ctx)) {
            let mut msg: [256]i8;
            afmt(msg, (u64)256, "'__asm__' requires an unsafe context: wrap it in '@unsafe { ... }', or mark the enclosing function '@unsafe fn'", .{});
            ana_error(ctx, node.line, msg);
        }
        return;
    }

    if (kind == nd_while_stmt) {
        let mut ws: *parser.while_stmt= (parser.while_stmt*)node;
        if (ws.cond != (parser.expr_node*)0) { ana_expr(ws.cond, ctx); }
        let mut outer_in_loop: bool= ctx.in_loop;
        ctx.in_loop = true;
        ctx.scope.push_scope();
        if (ws.body != (parser.ast_node*)0) { ana_stmt(ws.body, ctx); }
        ctx.scope.pop_scope();
        ctx.in_loop = outer_in_loop;
        return;
    }

    if (kind == nd_for_stmt) {
        let mut fs: *parser.for_stmt= (parser.for_stmt*)node;
        ctx.scope.push_scope();
        if (fs.init != (parser.ast_node*)0) { ana_stmt(fs.init, ctx); }
        if (fs.cond != (parser.expr_node*)0) { ana_expr(fs.cond, ctx); }
        if (fs.step != (parser.expr_node*)0) { ana_expr(fs.step, ctx); }
        let mut outer_in_loop_f: bool= ctx.in_loop;
        ctx.in_loop = true;
        if (fs.body != (parser.ast_node*)0) { ana_stmt(fs.body, ctx); }
        ctx.in_loop = outer_in_loop_f;
        ctx.scope.pop_scope();
        return;
    }

    if (kind == nd_for_range_stmt) {
        let mut frs: *parser.for_range_stmt= (parser.for_range_stmt*)node;
        if (frs.range != (parser.expr_node*)0) { ana_expr(frs.range, ctx); }
        ctx.scope.push_scope();
        if (frs.var_name != (i8*)0) {
            ctx.scope.declare(frs.var_name, sym_var, (i8*)0);
        }
        let mut outer_in_loop_r: bool= ctx.in_loop;
        ctx.in_loop = true;
        if (frs.body != (parser.ast_node*)0) { ana_stmt(frs.body, ctx); }
        ctx.in_loop = outer_in_loop_r;
        ctx.scope.pop_scope();
        return;
    }

    if (kind == nd_switch_stmt) {
        let mut ss: *parser.switch_stmt= (parser.switch_stmt*)node;
        if (ss.val != (parser.expr_node*)0) { ana_expr(ss.val, ctx); }
        let mut outer_in_loop_sw: bool= ctx.in_loop;
        ctx.in_loop = true;  // break is valid inside switch
        let mut ci: i32= 0;
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
            let mut msg: [256]i8;
            afmt(msg, (u64)256, "'try' cannot be used in function '%s' which does not return an error union (!T)", .{ ctx.cur_func_name != (i8*)0 ? ctx.cur_func_name : "?" });
            ana_error(ctx, (u64)0, msg);
        }
        let mut ts: *parser.try_expr_stmt= (parser.try_expr_stmt*)node;
        if (ts.expr != (parser.expr_node*)0) { ana_expr(ts.expr, ctx); }
        return;
    }

    if (kind == nd_match_stmt) {
        let mut ms: *parser.match_stmt= (parser.match_stmt*)node;
        // Analyze the subject expression
        if (ms.subject != (i8*)0) { ana_expr((parser.expr_node*)ms.subject, ctx); }
        // Exhaustiveness check: require at least one wildcard arm (_) when arms don't cover all cases.
        // Simple check: a match with no arms is an error; a match with no wildcard arm emits a warning.
        if (ms.arms_len == 0 && !ctx.in_generic) {
            let mut msg: [128]i8;
            afmt(msg, (u64)128, "match expression has no arms — unreachable", .{});
            ana_error(ctx, node.line, msg);
        } else {
            let mut has_wildcard: bool= false;
            let mut ai: i32= 0;
            while (ai < ms.arms_len) {
                if (ms.arms[ai] != (parser.match_arm*)0) {
                    let mut arm: *parser.match_arm= ms.arms[ai];
                    ctx.scope.push_scope();
                    // Register all bindings introduced by the pattern (including nested fields).
                    if (arm.pat != (parser.pat_node*)0) {
                        ana_register_pat_bindings(arm.pat, ctx);
                    }
                    // Analyze guard (bindings now in scope)
                    if (arm.guard != (i8*)0) { ana_expr((parser.expr_node*)arm.guard, ctx); }
                    if (arm.body != (parser.ast_node*)0) {
                        ana_stmt(arm.body, ctx);
                    }
                    ctx.scope.pop_scope();
                    // Check for wildcard arm: pk_wildcard = 0
                    if (arm.pat != (parser.pat_node*)0 && arm.pat.kind == 0) {
                        has_wildcard = true;
                    }
                }
                ai = ai + 1;
            }
            // Exhaustiveness: with no wildcard arm, an enum subject must name every
            // variant. Only checked when the subject is a plain identifier whose
            // declared type resolves to an enum — otherwise the type is unknown here
            // and silence is the correct answer.
            if (!has_wildcard && ms.arms_len > 0 && !ctx.in_generic) {
                let mut subj_e: *parser.expr_node= (parser.expr_node*)ms.subject;
                if (subj_e != (parser.expr_node*)0 && subj_e.kind == (i32)ek_identifier &&
                        subj_e.str_val != (i8*)0) {
                    let mut sub_vd: *i8= ctx.scope.lookup(subj_e.str_val);
                    let mut ename: *i8= (i8*)0;
                    if (sub_vd != (i8*)0 && sub_vd != (i8*)1 && sub_vd != (i8*)2) {
                        let mut svd: *parser.var_decl= (parser.var_decl*)sub_vd;
                        if (svd.type != (parser.type_node*)0) { ename = svd.type.name; }
                    }
                    if (ename != (i8*)0) {
                        let mut med: *parser.enum_decl= ana_enum_find(ctx, ename);
                        if (med != (parser.enum_decl*)0) {
                            let mut vi2: i32= 0;
                            while (vi2 < med.variants_len) {
                                let mut vn2: *i8= (med.variant_names != (i8**)0) ? med.variant_names[vi2] : (i8*)0;
                                if (vn2 != (i8*)0) {
                                    let mut covered: bool= false;
                                    let mut aj: i32= 0;
                                    while (aj < ms.arms_len && !covered) {
                                        let mut arm2: *parser.match_arm= ms.arms[aj];
                                        if (arm2 != (parser.match_arm*)0 && arm2.pat != (parser.pat_node*)0 &&
                                                arm2.pat.name != (i8*)0) {
                                            // Arm names arrive either bare ("Circle") or
                                            // enum-qualified ("Shape__Circle").
                                            let mut pn: *i8= arm2.pat.name;
                                            let mut en_len: i32= (i32)strlen(ename);
                                            if (strncmp(pn, ename, (u64)en_len) == 0 &&
                                                pn[en_len] == '_' && pn[en_len + 1] == '_') {
                                                pn = pn + en_len + 2;
                                            }
                                            if (strcmp(pn, vn2) == 0) { covered = true; }
                                        }
                                        aj = aj + 1;
                                    }
                                    if (!covered) {
                                        let mut msg_ex: [256]i8;
                                        afmt(msg_ex, (u64)256, "non-exhaustive match on '%s': variant '%s' is not handled (add it, or a '_' arm)", .{ ename, vn2 });
                                        ana_error(ctx, node.line, msg_ex);
                                    }
                                }
                                vi2 = vi2 + 1;
                            }
                        }
                    }
                }
            }
        }
        return;
    }
}

fn ana_block(blk: *parser.block_stmt, ctx: *ana_ctx) void {
    if (blk == (parser.block_stmt*)0) { return; }
    // `@unsafe { ... }` opens an unsafe region covering the statements it contains.
    if (blk.is_unsafe) { ctx.unsafe_depth = ctx.unsafe_depth + 1; }
    let mut i: i32= 0;
    while (i < blk.stmts_len) {
        if (blk.stmts != (parser.ast_node**)0) { ana_stmt(blk.stmts[i], ctx); }
        i = i + 1;
    }
    if (blk.is_unsafe) { ctx.unsafe_depth = ctx.unsafe_depth - 1; }
}

// True when unsafe operations are permitted at the current point: inside an
// `@unsafe { }` region, inside an `@unsafe fn` body, inside a memstr allocator type
// (which exists precisely to hold raw memory operations), or under --unsafe.
fn ana_in_unsafe_ctx(ctx: *ana_ctx) bool {
    return ctx.unsafe_depth > 0 || ctx.cur_func_is_unsafe ||
           ctx.cur_func_in_memstr_istruc || ctx.is_unsafe;
}

// ---- Function analysis ----

fn ana_func(fd: *parser.func_decl, ctx: *ana_ctx) void {
    if (fd == (parser.func_decl*)0 || !fd.has_body) { return; }

    let mut outer_in_func: bool= ctx.in_func;
    let mut outer_func_name: *i8= ctx.cur_func_name;
    let mut outer_func_void: bool= ctx.cur_func_is_void;
    let mut outer_func_eu: bool= ctx.cur_func_is_error_union;
    let mut outer_func_memstr: bool= ctx.cur_func_has_memstr_param;
    let mut outer_func_is_main: bool= ctx.cur_func_is_main;
    let mut outer_in_istruc: bool= ctx.cur_func_in_istruc;
    let mut outer_in_memstr_istruc: bool= ctx.cur_func_in_memstr_istruc;
    let mut outer_func_is_unsafe: bool= ctx.cur_func_is_unsafe;
    let mut outer_generic: bool= ctx.in_generic;
    if (fd.type_params_len > 0) { ctx.in_generic = true; }

    ctx.in_func            = true;
    ctx.cur_func_is_unsafe = fd.is_unsafe;
    ctx.cur_func_name      = fd.name;
    let mut is_main_func: bool= (fd.name != (i8*)0 && strcmp(fd.name, "main") == 0);
    ctx.cur_func_is_main = is_main_func;

    // Require main() to be marked pub
    if (is_main_func && !fd.is_pub) {
        aprint("error at line %llu: 'main' must be declared 'pub fn main()'\n", .{ fd.line });
        ctx.error_count = ctx.error_count + 1;
    }

    let mut is_void: bool= (fd.ret_type == (parser.type_node*)0);
    // !void means error-union returning void — not truly void; can still `return error.X`
    if (!is_void && fd.ret_type.is_primitive && fd.ret_type.prim == (i32)void_t && fd.ret_type.pointer_depth == 0 && !fd.is_error_union) { is_void = true; }
    ctx.cur_func_is_void = is_void;
    ctx.cur_func_is_error_union = fd.is_error_union;

    // Check if any param is &memstr
    let mut has_memstr: bool= false;
    let mut mpi: i32= 0;
    while (mpi < fd.params_len) {
        if (fd.params != (parser.param_decl*)0) {
            let mut ptype: *parser.type_node= fd.params[mpi].type;
            if (ptype != (parser.type_node*)0 && ptype.is_memstr_ref) { has_memstr = true; }
        }
        mpi = mpi + 1;
    }
    ctx.cur_func_has_memstr_param = has_memstr;

    ctx.scope.push_scope();

    // Declare implicit `self` for istruc methods that don't use an explicit self pointer as first param
    if (ctx.cur_func_in_istruc) {
        let mut has_explicit_self: bool= false;
        if (fd.params_len > 0 && fd.params != (parser.param_decl*)0) {
            let mut fp: *parser.type_node= fd.params[0].type;
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
        let mut tpi: i32= 0;
        while (tpi < fd.type_params_len) {
            if (fd.type_params != (i8**)0 && fd.type_params[tpi] != (i8*)0) {
                ctx.scope.declare(fd.type_params[tpi], (i32)sym_type, (i8*)0);
            }
            tpi = tpi + 1;
        }
    }

    // Register parameters
    let mut pi: i32= 0;
    while (pi < fd.params_len) {
        if (fd.params != (parser.param_decl*)0 && fd.params[pi].name != (i8*)0) {
            let mut param_is_fptr: bool= (fd.params[pi].type != (parser.type_node*)0 && fd.params[pi].type.is_func_ptr);
            let mut param_kind: i32= param_is_fptr ? (i32)sym_func_ptr : (i32)sym_var;
            // Store (i8*)2 as sentinel for &memstr params so pass-through args can be detected
            let mut param_is_memstr: bool= (fd.params[pi].type != (parser.type_node*)0 && fd.params[pi].type.is_memstr_ref);
            let mut param_data: *i8= param_is_memstr ? (i8*)2 : (i8*)0;
            ctx.scope.declare(fd.params[pi].name, param_kind, param_data);
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
    ctx.cur_func_is_unsafe          = outer_func_is_unsafe;
    ctx.in_generic                  = outer_generic;
}

// ---- Top-level collection ----

fn collect_toplevel(node: *parser.ast_node, ctx: *ana_ctx) void {
    if (node == (parser.ast_node*)0) { return; }
    let mut kind: i32= node.kind;

    if (kind == nd_func_decl) {
        let mut fd: *parser.func_decl= (parser.func_decl*)node;
        // The @unsafe requirement for bodyless declarations is checked in
        // ana_check_foreign_decls, after every definition in the program is known —
        // a prototype paired with a later definition is not a foreign declaration.
        if (fd.name != (i8*)0) {
            let mut fd_is_void: bool= (fd.ret_type == (parser.type_node*)0) ||
                              (fd.ret_type.is_primitive && fd.ret_type.prim == (i32)void_t);
            if (fd.has_body) {
                // Check if a prior DEFINITION (has_body) exists; prototype+definition is OK
                let mut prior: *i8= ctx.scope.lookup(fd.name);
                let mut prior_has_body: bool= false;
                if (prior != (i8*)0) {
                    let mut prior_fd: *parser.func_decl= (parser.func_decl*)prior;
                    prior_has_body = prior_fd.has_body;
                }
                if (prior_has_body) {
                    let mut msg: [256]i8;
                    afmt(msg, (u64)256, "duplicate definition of function '%s'", .{ fd.name });
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
        let mut vd: *parser.var_decl= (parser.var_decl*)node;
        if (vd.name != (i8*)0) {
            let mut is_fptr: bool= (vd.type != (parser.type_node*)0 && vd.type.is_func_ptr);
            // const NAME = ns.func or const NAME = lambda → callable
            let mut is_auto_t: bool= (vd.type == (parser.type_node*)0 ||
                                      (vd.type != (parser.type_node*)0 && vd.type.is_auto));
            // const NAME = ns.func or const NAME = lambda → callable
            let mut is_fn_init: bool= (is_auto_t &&
                                       vd.init != (parser.expr_node*)0 &&
                                       (vd.init.kind == (i32)ek_member ||
                                        vd.init.kind == (i32)ek_lambda));
            let mut var_kind: i32= (is_fptr || is_fn_init) ? (i32)sym_func_ptr : (i32)sym_var;
            ctx.scope.declare(vd.name, var_kind, (i8*)0);
        }
        return;
    }
    if (kind == nd_enum_decl) {
        let mut ed: *parser.enum_decl= (parser.enum_decl*)node;
        // Register enum name — error on redeclaration
        if (ed.name != (i8*)0) {
            if (ctx.scope.exists(ed.name)) {
                let mut msg: [256]i8;
                afmt(msg, (u64)256, "redeclaration of enum '%s'", .{ ed.name });
                ana_error(ctx, ed.line, msg);
            } else {
                ctx.scope.declare(ed.name, sym_enum, (i8*)0);
                ana_enum_reg(ctx, ed.name, ed);
            }
        }
        // Register all variant/constant names
        let mut vi: i32= 0;
        while (vi < ed.variants_len) {
            if (ed.variant_names != (i8**)0 && ed.variant_names[vi] != (i8*)0) {
                let mut vname: *i8= ed.variant_names[vi];
                if (!ctx.scope.exists(vname)) {
                    ctx.scope.declare(vname, sym_var, (i8*)0);
                }
            }
            vi = vi + 1;
        }
        return;
    }
    if (kind == nd_typedef_decl) {
        let mut td: *parser.typedef_decl= (parser.typedef_decl*)node;
        if (td.name != (i8*)0 && !ctx.scope.exists(td.name)) {
            ctx.scope.declare(td.name, sym_type, (i8*)0);
        }
        return;
    }
    if (kind == nd_extern_c_block) {
        let mut ecb: *parser.extern_c_block= (parser.extern_c_block*)node;
        let mut ei: i32= 0;
        while (ei < ecb.decls_len) {
            if (ecb.decls != (parser.ast_node**)0) { collect_toplevel(ecb.decls[ei], ctx); }
            ei = ei + 1;
        }
        return;
    }
    if (kind == nd_struct_decl) {
        let mut sd: *parser.struct_decl= (parser.struct_decl*)node;
        if (sd.name != (i8*)0) {
            if (ctx.scope.lookup_struct(sd.name) != (i8*)0) {
                let mut msg: [256]i8;
                afmt(msg, (u64)256, "duplicate struct declaration '%s'", .{ sd.name });
                ana_error(ctx, sd.line, msg);
            } else {
                ctx.scope.declare_struct(sd.name, node);
            }
        }
        return;
    }
    if (kind == nd_namespace_decl) {
        let mut nd: *parser.namespace_decl= (parser.namespace_decl*)node;
        // Generic class: register the name only, skip child analysis until monomorphization.
        // For generic enums, also register variant names so bare usage passes analysis.
        if (nd.type_params_len > 0) {
            if (!ctx.scope.exists(nd.name)) {
                ctx.scope.declare(nd.name, sym_type, (i8*)nd);
            }
            let mut ci: i32= 0;
            while (ci < nd.decls_len) {
                let mut gc: *parser.ast_node= (nd.decls != (parser.ast_node**)0) ? nd.decls[ci] : (parser.ast_node*)0;
                if (gc != (parser.ast_node*)0 && gc.kind == nd_enum_decl) {
                    let mut ged2: *parser.enum_decl= (parser.enum_decl*)gc;
                    let mut gvi: i32= 0;
                    while (gvi < ged2.variants_len) {
                        let mut gvname: *i8= (ged2.variant_names != (i8**)0) ? ged2.variant_names[gvi] : (i8*)0;
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
            let mut ai2: i32= 0;
            while (ai2 < nd.attributes_len) {
                let mut pattr_val: parser.proc_attr= nd.attributes[ai2];
                if (pattr_val.name != (i8*)0 && strcmp(pattr_val.name, "derive") == 0) {
                    let mut darg: i32= 0;
                    while (darg < pattr_val.args_len) {
                        let mut trait_name: *i8= (pattr_val.args != (i8**)0) ? pattr_val.args[darg] : (i8*)0;
                        if (trait_name != (i8*)0) {
                            let mut known: bool= false;
                            if (strcmp(trait_name, "Debug") == 0)   { known = true; }
                            if (strcmp(trait_name, "Clone") == 0)   { known = true; }
                            if (strcmp(trait_name, "Default") == 0) { known = true; }
                            if (strcmp(trait_name, "PartialEq") == 0) { known = true; }
                            if (strcmp(trait_name, "Eq") == 0)      { known = true; }
                            if (strcmp(trait_name, "Hash") == 0)    { known = true; }
                            if (!known) {
                                let mut msg: [256]i8;
                                afmt(msg, (u64)256, "unknown derive macro '%s'", .{ trait_name });
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
                    let mut msg: [256]i8;
                    afmt(msg, (u64)256, "redeclaration of '%s'", .{ nd.name });
                    ana_error(ctx, nd.line, msg);
                } else {
                    ctx.scope.declare(nd.name, sym_type, (i8*)nd);
                }
                // Check base classes/interfaces
                let mut bi: i32= 0;
                while (bi < nd.bases_len) {
                    let mut bname: *i8= (nd.bases != (i8**)0) ? nd.bases[bi] : (i8*)0;
                    if (bname != (i8*)0) {
                        // Check that base type is known
                        if (!ctx.scope.exists(bname) && ctx.scope.lookup_struct(bname) == (i8*)0) {
                            let mut msg: [256]i8;
                            afmt(msg, (u64)256, "unknown base type '%s'", .{ bname });
                            ana_error(ctx, nd.line, msg);
                        } else if (!nd.is_interface) {
                            // Non-interface istruc: check base
                            let mut base_ptr: *i8= ctx.scope.lookup(bname);
                            if (base_ptr != (i8*)0 && base_ptr != (i8*)1) {
                                let mut base_nd: *parser.namespace_decl= (parser.namespace_decl*)base_ptr;
                                if (base_nd.is_istruc && !base_nd.is_interface) {
                                    let mut msg: [256]i8;
                                    afmt(msg, (u64)256, "cannot inherit from '%s': class inheritance is not supported", .{ bname });
                                    ana_error(ctx, nd.line, msg);
                                } else if (base_nd.is_interface) {
                                    // Check that this istruc implements all required methods from the interface
                                    let mut ifm: i32= 0;
                                    while (ifm < base_nd.decls_len) {
                                        let mut ifdecl: *parser.ast_node= (base_nd.decls != (parser.ast_node**)0) ? base_nd.decls[ifm] : (parser.ast_node*)0;
                                        if (ifdecl != (parser.ast_node*)0 && ifdecl.kind == nd_func_decl) {
                                            let mut ifd: *parser.func_decl= (parser.func_decl*)ifdecl;
                                            if (ifd.name != (i8*)0 && !ifd.has_body) {
                                                // Required method (no body = abstract)
                                                let mut found_impl: bool= false;
                                                let mut mi: i32= 0;
                                                while (mi < nd.decls_len) {
                                                    let mut mdecl: *parser.ast_node= (nd.decls != (parser.ast_node**)0) ? nd.decls[mi] : (parser.ast_node*)0;
                                                    if (mdecl != (parser.ast_node*)0 && mdecl.kind == nd_func_decl) {
                                                        let mut mfd: *parser.func_decl= (parser.func_decl*)mdecl;
                                                        if (mfd.name != (i8*)0 && strcmp(mfd.name, ifd.name) == 0) {
                                                            found_impl = true;
                                                        }
                                                    }
                                                    mi = mi + 1;
                                                }
                                                if (!found_impl) {
                                                    let mut msg: [256]i8;
                                                    afmt(msg, (u64)256, "'%s' does not implement '%s' required by interface '%s'", .{ nd.name, ifd.name, bname });
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
        let mut local_methods: [128]*i8;
        let mut local_method_count: i32= 0;
        let mut i: i32= 0;
        while (i < nd.decls_len) {
            let mut child: *parser.ast_node= (nd.decls != (parser.ast_node**)0) ? nd.decls[i] : (parser.ast_node*)0;
            if (child != (parser.ast_node*)0 && child.kind == nd_func_decl) {
                let mut cfd: *parser.func_decl= (parser.func_decl*)child;
                if (cfd.name != (i8*)0) {
                    if (cfd.has_body && nd.is_istruc) {
                        // Check for duplicate method within this istruc
                        let mut is_dup: bool= false;
                        let mut si: i32= 0;
                        while (si < local_method_count) {
                            if (strcmp(local_methods[si], cfd.name) == 0) { is_dup = true; break; }
                            si = si + 1;
                        }
                        if (is_dup) {
                            let mut msg: [256]i8;
                            afmt(msg, (u64)256, "method overloading is not supported: '%s' defined more than once", .{ cfd.name });
                            ana_error(ctx, cfd.line, msg);
                        } else {
                            if (local_method_count < 128) {
                                local_methods[local_method_count] = cfd.name;
                                local_method_count = local_method_count + 1;
                            }
                        }
                    }
                    {
                        // Plain namespace functions overwrite any earlier entry so that
                        // cross-namespace same-named functions don't silently use the wrong
                        // parameter count. istruc/memstr methods are dispatched through the
                        // type and validated against its method table, so they must not
                        // clobber a top-level function sharing their name — otherwise a
                        // memstr allocator's `free(self, p)` would make the global `free(p)`
                        // look like it takes two arguments.
                        let mut is_method: bool= nd.is_istruc || nd.is_memstr;
                        let mut cfd_is_void: bool= (cfd.ret_type == (parser.type_node*)0) ||
                                           (cfd.ret_type.is_primitive && cfd.ret_type.prim == (i32)void_t);
                        if (is_method) {
                            // Register under the qualified name only. Under the bare name a
                            // method would collide with a same-named global in *either* order:
                            // seen first it claims the name and the real global is then
                            // reported as a duplicate definition; seen second it was already
                            // skipped. memstr's `free(self, p)` beside libc's `free(p)` is the
                            // case that matters. Method calls are checked against the type's
                            // own method table, so the bare name is never needed here.
                            // str_dup is required: the symbol table borrows the name
                            // pointer, so a stack buffer would dangle the moment this
                            // function returns and the entry would then compare against
                            // whatever later reused that stack slot.
                            let mut qn_m: [512]i8;
                            afmt(qn_m, (u64)512, "%s__NS_%s", .{ nd.name != (i8*)0 ? nd.name : "?", cfd.name });
                            ctx.scope.declare_func_v(lexer.str_dup(qn_m), (i8*)cfd, cfd.params_len, cfd.is_variadic, cfd_is_void);
                        } else {
                            ctx.scope.declare_func_v(cfd.name, (i8*)cfd, cfd.params_len, cfd.is_variadic, cfd_is_void);
                        }
                    }
                }
            } else if (child != (parser.ast_node*)0 && child.kind == nd_var_decl) {
                let mut cvd: *parser.var_decl= (parser.var_decl*)child;
                if (cvd.name != (i8*)0 && !ctx.scope.exists(cvd.name)) {
                    let mut cvd_is_fptr: bool= (cvd.type != (parser.type_node*)0 && cvd.type.is_func_ptr);
                    // const NAME = mod.func or const NAME = lambda → callable
                    let mut cvd_is_auto_t: bool= (cvd.type == (parser.type_node*)0 ||
                                                   (cvd.type != (parser.type_node*)0 && cvd.type.is_auto));
                    // const NAME = ns.func or const NAME = lambda → callable
                    let mut cvd_is_fn_init: bool= (cvd_is_auto_t &&
                                                   cvd.init != (parser.expr_node*)0 &&
                                                   (cvd.init.kind == (i32)ek_member ||
                                                    cvd.init.kind == (i32)ek_lambda));
                    let mut cvd_kind: i32= (cvd_is_fptr || cvd_is_fn_init) ? (i32)sym_func_ptr : (i32)sym_var;
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

fn analyze_bodies(node: *parser.ast_node, ctx: *ana_ctx) void {
    if (node == (parser.ast_node*)0) { return; }
    let mut kind: i32= node.kind;

    if (kind == nd_func_decl) {
        let mut fd: *parser.func_decl= (parser.func_decl*)node;
        // Skip type checking for generic functions or functions inside generic namespaces
        if (fd.type_params_len == 0 && !ctx.in_generic) {
            // Check return type
            if (fd.ret_type != (parser.type_node*)0 && !is_type_known(fd.ret_type, ctx)) {
                if (fd.ret_type.name != (i8*)0) {
                    let mut msg: [256]i8;
                    afmt(msg, (u64)256, "unknown return type '%s' in function '%s'", .{ fd.ret_type.name, fd.name });
                    ana_error(ctx, fd.line, msg);
                }
            }
            // Check param types
            let mut pi: i32= 0;
            while (pi < fd.params_len) {
                if (fd.params != (parser.param_decl*)0 && fd.params[pi].type != (parser.type_node*)0) {
                    if (!is_type_known(fd.params[pi].type, ctx)) {
                        if (fd.params[pi].type.name != (i8*)0) {
                            let mut msg: [256]i8;
                            afmt(msg, (u64)256, "unknown param type '%s' in function '%s'", .{ fd.params[pi].type.name, fd.name });
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
        let mut nd: *parser.namespace_decl= (parser.namespace_decl*)node;
        let mut outer_generic: bool= ctx.in_generic;
        let mut outer_in_istruc: bool= ctx.cur_func_in_istruc;
        let mut outer_in_memstr_istruc2: bool= ctx.cur_func_in_memstr_istruc;
        if (nd.is_istruc) { ctx.cur_func_in_istruc = true; }
        if (nd.is_memstr) { ctx.cur_func_in_memstr_istruc = true; }
        let mut pushed_tp_scope: bool= false;
        if (nd.type_params_len > 0) {
            ctx.in_generic = true;
            ctx.scope.push_scope();
            pushed_tp_scope = true;
            let mut tpi: i32= 0;
            while (tpi < nd.type_params_len) {
                if (nd.type_params != (i8**)0 && nd.type_params[tpi] != (i8*)0) {
                    ctx.scope.declare(nd.type_params[tpi], (i32)sym_type, (i8*)0);
                }
                tpi = tpi + 1;
            }
        }
        let mut i: i32= 0;
        while (i < nd.decls_len) {
            let mut ndchild: *parser.ast_node= (nd.decls != (parser.ast_node**)0) ? nd.decls[i] : (parser.ast_node*)0;
            if (ndchild != (parser.ast_node*)0) {
                // For istruc field var_decls, also check field types (skip in generic context)
                if (ndchild.kind == nd_var_decl && !ctx.in_generic) {
                    let mut fvd: *parser.var_decl= (parser.var_decl*)ndchild;
                    if (fvd.type != (parser.type_node*)0 && !is_type_known(fvd.type, ctx)) {
                        if (fvd.type.name != (i8*)0) {
                            let mut msg: [256]i8;
                            afmt(msg, (u64)256, "unknown type '%s' in field '%s'", .{ fvd.type.name, fvd.name });
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
        let mut sd: *parser.struct_decl= (parser.struct_decl*)node;
        // Skip type checking when inside a generic namespace (type params like T are not in scope)
        if (!ctx.in_generic) {
            let mut fi: i32= 0;
            while (fi < sd.fields_len) {
                if (sd.fields != (parser.var_decl**)0 && sd.fields[fi] != (parser.var_decl*)0) {
                    let mut f: *parser.var_decl= sd.fields[fi];
                    if (f.type != (parser.type_node*)0 && !is_type_known(f.type, ctx)) {
                        if (f.type.name != (i8*)0) {
                            let mut msg: [256]i8;
                            afmt(msg, (u64)256, "unknown type '%s' in struct field '%s'", .{ f.type.name, f.name });
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
        let mut td: *parser.typedef_decl= (parser.typedef_decl*)node;
        if (!td.is_namespace_using && td.target != (parser.type_node*)0) {
            if (!is_type_known(td.target, ctx)) {
                if (td.target.name != (i8*)0) {
                    let mut msg: [256]i8;
                    afmt(msg, (u64)256, "unknown type '%s' in using/typedef declaration", .{ td.target.name });
                    ana_error(ctx, td.line, msg);
                }
            }
        }
        return;
    }
    if (kind == nd_var_decl) {
        let mut vd: *parser.var_decl= (parser.var_decl*)node;
        if (!ctx.in_generic && vd.type != (parser.type_node*)0 && !is_type_known(vd.type, ctx)) {
            if (vd.type.name != (i8*)0) {
                let mut msg: [256]i8;
                afmt(msg, (u64)256, "unknown type '%s'", .{ vd.type.name });
                ana_error(ctx, vd.line, msg);
            }
        }
        if (vd.init != (parser.expr_node*)0) { ana_expr(vd.init, ctx); }
    }
}

// ---- Entry point ----

fn analyze(prog: *parser.program_node) i32 {
    return analyze_unsafe(prog, false);
}

// A function declaration with no body is a *foreign* declaration: its definition
// comes from outside this program, so nothing about it can be verified and it must
// carry @unsafe. This covers all three spellings — `extern fn f();`, a member of an
// `extern "C" { ... }` block, and a bare prototype `fn f();` — because the marker is
// only worth anything as a complete inventory of the trust boundary. A spelling that
// can skip it makes @unsafe misleading rather than merely incomplete.
//
// A prototype paired with a definition elsewhere in the program is not foreign, so
// this runs after every definition has been collected.
fn ana_check_foreign_decls(node: *parser.ast_node, ctx: *ana_ctx) void {
    if (node == (parser.ast_node*)0) { return; }
    let mut kind: i32= node.kind;

    if (kind == nd_func_decl) {
        let mut fd: *parser.func_decl= (parser.func_decl*)node;
        if (fd.has_body || fd.is_unsafe || fd.name == (i8*)0) { return; }
        // Resolved definition elsewhere in the program → a forward declaration.
        let mut resolved: *i8= ctx.scope.lookup(fd.name);
        if (resolved != (i8*)0 && resolved != (i8*)1 && resolved != (i8*)2) {
            let mut rfd: *parser.func_decl= (parser.func_decl*)resolved;
            if (rfd.has_body) { return; }
        }
        let mut fn_name2: *i8= fd.name;
        let mut msg: [256]i8;
        if (fd.is_extern_c && !fd.is_extern_kw) {
            afmt(msg, (u64)256, "'%s' is declared in an extern \"C\" block and requires '@unsafe': write '@unsafe extern \"C\" { ... }'", .{ fn_name2 });
        } else if (fd.is_extern_kw) {
            afmt(msg, (u64)256, "extern fn '%s' requires '@unsafe' prefix: '@unsafe extern fn %s(...)'", .{ fn_name2, fn_name2 });
        } else {
            afmt(msg, (u64)256, "'%s' is declared without a body and requires '@unsafe': write '@unsafe extern fn %s(...)', or give it a body", .{ fn_name2, fn_name2 });
        }
        ana_error(ctx, fd.line, msg);
        return;
    }

    if (kind == nd_extern_c_block) {
        let mut ecb: *parser.extern_c_block= (parser.extern_c_block*)node;
        let mut i: i32= 0;
        while (i < ecb.decls_len) {
            if (ecb.decls != (parser.ast_node**)0) { ana_check_foreign_decls(ecb.decls[i], ctx); }
            i = i + 1;
        }
        return;
    }

    if (kind == nd_namespace_decl) {
        let mut nd: *parser.namespace_decl= (parser.namespace_decl*)node;
        // An interface's methods are bodyless by definition — they are a contract for
        // implementors, not foreign declarations, and the implementations are checked
        // where they are written.
        if (nd.is_interface) { return; }
        let mut i: i32= 0;
        while (i < nd.decls_len) {
            if (nd.decls != (parser.ast_node**)0) { ana_check_foreign_decls(nd.decls[i], ctx); }
            i = i + 1;
        }
        return;
    }
}

fn analyze_unsafe(prog: *parser.program_node, unsafe_mode: bool) i32 {
    if (prog == (parser.program_node*)0) { return 0; }

    let mut ctx: ana_ctx;
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
    ctx.cur_func_is_unsafe        = false;
    ctx.in_loop                   = false;
    ctx.in_generic                = false;
    ctx.is_unsafe                 = unsafe_mode;
    ctx.enum_count                = 0;
    ctx.unsafe_depth              = 0;

    // Pass 1: collect all top-level symbol names
    let mut i: i32= 0;
    while (i < prog.decls_len) {
        if (prog.decls != (parser.ast_node**)0) { collect_toplevel(prog.decls[i], &ctx); }
        i = i + 1;
    }

    // Pass 1b: now that every definition is known, require @unsafe on declarations
    // whose body lives outside this program.
    let mut fi: i32= 0;
    while (fi < prog.decls_len) {
        if (prog.decls != (parser.ast_node**)0) { ana_check_foreign_decls(prog.decls[fi], &ctx); }
        fi = fi + 1;
    }

    // Pass 2: analyze function bodies and global initializers
    let mut j: i32= 0;
    while (j < prog.decls_len) {
        if (prog.decls != (parser.ast_node**)0) { analyze_bodies(prog.decls[j], &ctx); }
        j = j + 1;
    }

    return ctx.error_count;
}

} // namespace analysis
