// Declaration IR generation for the Artemis self-hosting compiler.

namespace ir {

// Forward declaration
void visit_top_level_decl(parser.ast_node* node, ir_context* ctx);

// ---- Struct declaration ----

void visit_struct_decl(parser.struct_decl* d, ir_context* ctx) {
    // Create an opaque named struct and register it
    i8* struct_t = LLVMStructCreateNamed(ctx.llvm_ctx, d.name);
    st_map_set(&ctx.struct_types, d.name, struct_t);

    // Build field type arrays
    i32 nfields = d.fields_len;
    i8** field_types_arr = (i8**)malloc(sizeof(i8*) * (u64)nfields);

    struct_meta sm;
    sm.name = d.name;
    name_list_init(&sm.field_names);
    type_list_init(&sm.field_types);
    bool_list_init(&sm.field_unsigned);
    type_list_init(&sm.field_pointee);

    i32 i = 0;
    while (i < nfields) {
        parser.var_decl* f = d.fields[i];
        i8* ft = llvm_type_of(f.type, ctx);
        field_types_arr[i] = ft;
        name_list_push(&sm.field_names, f.name);
        type_list_push(&sm.field_types, ft);
        bool_list_push(&sm.field_unsigned, is_unsigned_type_node(f.type));

        i8* pointee_t = (i8*)0;
        if (f.type != (parser.type_node*)0 && f.type.pointer_depth > 0) {
            parser.type_node stripped;
            stripped = *f.type;
            stripped.pointer_depth = stripped.pointer_depth - 1;
            pointee_t = llvm_type_of(&stripped, ctx);
        }
        type_list_push(&sm.field_pointee, pointee_t);
        i = i + 1;
    }

    LLVMStructSetBody(struct_t, field_types_arr, nfields, 0);
    free((i8*)field_types_arr);

    struct_meta_vec_push(&ctx.struct_meta_tbl, sm);
}

// ---- Enum declaration ----

void visit_enum_decl(parser.enum_decl* d, ir_context* ctx) {
    i8* i32t = LLVMInt32TypeInContext(ctx.llvm_ctx);
    i64 next_val = 0;
    i32 i = 0;
    while (i < d.variants_len) {
        if (d.variant_has_val[i]) {
            next_val = d.variant_vals[i];
        }
        // Register as global constant: EnumName__VariantName
        i8 qname[512];
        snprintf(qname, (u64)512, "%s__%s", d.name, d.variant_names[i]);
        i8* gv = LLVMAddGlobal(ctx.llvm_mod, i32t, qname);
        LLVMSetInitializer(gv, LLVMConstInt(i32t, (u64)next_val, 1));
        LLVMSetGlobalConstant(gv, 1);
        LLVMSetLinkage(gv, LLVMInternalLinkage);
        sv_map_set(&ctx.global_vars, qname, gv);

        // Also register bare name for same-scope access
        sv_map_set(&ctx.global_vars, d.variant_names[i], gv);

        next_val = next_val + 1;
        i = i + 1;
    }
}

// ---- Typedef declaration ----

void visit_typedef_decl(parser.typedef_decl* d, ir_context* ctx) {
    if (d.target == (parser.type_node*)0 || d.name == (i8*)0) { return; }

    // Check if target is a struct type
    bool target_is_struct = false;
    if (!d.target.is_primitive && d.target.name != (i8*)0 && d.target.pointer_depth == 0) {
        i8* found = st_map_get(&ctx.struct_types, d.target.name);
        if (found != (i8*)0) {
            st_map_set(&ctx.struct_types, d.name, found);
            target_is_struct = true;
        }
    }
    if (!target_is_struct) {
        typedef_map_set(&ctx.typedef_aliases, d.name, (i8*)d.target);
    }
}

// ---- Function prototype (pass 1) ----

void visit_func_decl_prototype(parser.func_decl* fd, ir_context* ctx) {
    i8* fn_name = ir_func_name(fd);

    // Build return type
    i8* ret_t = (i8*)0;
    if (fd.ret_type != (parser.type_node*)0) {
        ret_t = llvm_type_of(fd.ret_type, ctx);
    }
    if (ret_t == (i8*)0) {
        ret_t = LLVMVoidTypeInContext(ctx.llvm_ctx);
    }

    // Build parameter types
    i32 nparams = fd.params_len;
    i8** param_types = (i8**)0;
    if (nparams > 0) {
        param_types = (i8**)malloc(sizeof(i8*) * (u64)nparams);
        i32 i = 0;
        while (i < nparams) {
            i8* pt = llvm_type_of(fd.params[i].type, ctx);
            if (pt == (i8*)0) { pt = LLVMVoidTypeInContext(ctx.llvm_ctx); }
            param_types[i] = pt;
            i = i + 1;
        }
    }
    i32 variadic = fd.is_variadic ? 1 : 0;
    i8* fn_type  = LLVMFunctionType(ret_t, param_types, nparams, variadic);
    if (param_types != (i8**)0) { free((i8*)param_types); }

    // Check if already declared (extern prototype)
    i8* existing = sv_map_get(&ctx.global_funcs, fn_name);
    i8* fn = (i8*)0;
    if (existing != (i8*)0) {
        fn = existing;
    } else {
        fn = LLVMAddFunction(ctx.llvm_mod, fn_name, fn_type);
    }

    sv_map_set(&ctx.global_funcs,           fn_name, fn);
    st_map_set(&ctx.global_func_types,      fn_name, fn_type);
    bool ret_uns = is_unsigned_type_node(fd.ret_type);
    sb_map_set(&ctx.global_func_ret_unsigned, fn_name, ret_uns);
}

// ---- Function body (pass 2) ----

void visit_func_decl(parser.func_decl* fd, ir_context* ctx) {
    if (!fd.has_body) { return; }
    i8* fn_name = ir_func_name(fd);
    i8* fn      = sv_map_get(&ctx.global_funcs, fn_name);
    i8* fn_type = st_map_get(&ctx.global_func_types, fn_name);
    if (fn == (i8*)0 || fn_type == (i8*)0) { return; }

    i8* entry_bb = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "entry");
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, entry_bb);

    ctx.current_func      = fn;
    ctx.current_func_type = fn_type;

    i8* ret_t = (i8*)0;
    if (fd.ret_type != (parser.type_node*)0) {
        ret_t = llvm_type_of(fd.ret_type, ctx);
    }
    ctx.current_ret_type = ret_t;

    // Push function scope
    ctx_push_scope(ctx);

    // Alloca for each parameter
    i32 i = 0;
    while (i < fd.params_len) {
        parser.param_decl p = fd.params[i];
        i8* param_val = LLVMGetParam(fn, i);
        i8* pt        = llvm_type_of(p.type, ctx);
        i8* alloca    = LLVMBuildAlloca(ctx.llvm_builder, pt, p.name != (i8*)0 ? p.name : "arg");
        LLVMBuildStore(ctx.llvm_builder, param_val, alloca);

        i8* deref_t = (i8*)0;
        if (p.type != (parser.type_node*)0 && p.type.pointer_depth > 0) {
            parser.type_node stripped;
            stripped = *p.type;
            stripped.pointer_depth = stripped.pointer_depth - 1;
            deref_t = llvm_type_of(&stripped, ctx);
        }
        bool puns = is_unsigned_type_node(p.type);
        ctx_declare_local(ctx, p.name != (i8*)0 ? p.name : "arg", alloca, pt, deref_t, puns);
        i = i + 1;
    }

    // Emit body
    if (fd.body != (i8*)0) {
        parser.block_stmt* blk = (parser.block_stmt*)fd.body;
        visit_block_stmt(blk, ctx);
    }

    // Ensure terminator
    if (!ctx_is_terminated(ctx)) {
        i8* rv = ctx.current_ret_type;
        if (rv == (i8*)0 || LLVMGetTypeKind(rv) == LLVMVoidTypeKind) {
            LLVMBuildRetVoid(ctx.llvm_builder);
        } else {
            LLVMBuildRet(ctx.llvm_builder, LLVMConstNull(rv));
        }
    }

    ctx_pop_scope(ctx);
    ctx.current_func      = (i8*)0;
    ctx.current_func_type = (i8*)0;
    ctx.current_ret_type  = (i8*)0;
}

// ---- Namespace ----

void visit_namespace_decl(parser.namespace_decl* nd, ir_context* ctx) {
    i8* saved_ns = ctx.current_namespace;
    i8 ns_buf[256];
    if (saved_ns != (i8*)0) {
        snprintf(ns_buf, (u64)256, "%s__NS_%s", saved_ns, nd.name);
    } else {
        snprintf(ns_buf, (u64)256, "%s", nd.name);
    }
    ctx.current_namespace = lexer.str_dup(ns_buf);

    // Pass 1: register types and prototypes
    i32 i = 0;
    while (i < nd.decls_len) {
        parser.ast_node* decl = nd.decls[i];
        if (decl != (parser.ast_node*)0) {
            i32 k = decl.kind;
            if (k == nd_struct_decl)   { visit_struct_decl((parser.struct_decl*)decl, ctx); }
            if (k == nd_enum_decl)     { visit_enum_decl((parser.enum_decl*)decl, ctx); }
            if (k == nd_typedef_decl)  { visit_typedef_decl((parser.typedef_decl*)decl, ctx); }
            if (k == nd_func_decl) {
                parser.func_decl* fd = (parser.func_decl*)decl;
                // Prefix the function name with the namespace
                i8 qname[512];
                snprintf(qname, (u64)512, "%s__NS_%s", nd.name, fd.name);
                // Store original name and temporarily set mangled_name
                i8* orig_name = fd.name;
                fd.name = lexer.str_dup(qname);
                visit_func_decl_prototype(fd, ctx);
                // Also register under plain name in case of same-ns calls
                sv_map_set(&ctx.global_funcs,      fd.name, sv_map_get(&ctx.global_funcs, fd.name));
                fd.name = orig_name;
            }
        }
        i = i + 1;
    }

    // Pass 2: emit bodies
    i32 j = 0;
    while (j < nd.decls_len) {
        parser.ast_node* decl = nd.decls[j];
        if (decl != (parser.ast_node*)0) {
            i32 k = decl.kind;
            if (k == nd_var_decl)  {
                // Global variable in namespace
                parser.var_decl* vd = (parser.var_decl*)decl;
                i8 qname[512];
                snprintf(qname, (u64)512, "%s__NS_%s", nd.name, vd.name);
                i8* gt = llvm_type_of(vd.type, ctx);
                i8* gv = LLVMAddGlobal(ctx.llvm_mod, gt, qname);
                i8* init_val = (i8*)0;
                if (vd.has_init) {
                    init_val = visit_expr(vd.init, ctx);
                    if (init_val != (i8*)0 && gt != (i8*)0 && LLVMTypeOf(init_val) != gt) {
                        i32 ik = LLVMGetTypeKind(LLVMTypeOf(init_val));
                        i32 gk = LLVMGetTypeKind(gt);
                        if (ik == LLVMIntegerTypeKind && gk == LLVMIntegerTypeKind) {
                            i64 raw = LLVMConstIntGetSExtValue(init_val);
                            init_val = LLVMConstInt(gt, (u64)raw, 1);
                        }
                    }
                }
                if (init_val != (i8*)0) {
                    LLVMSetInitializer(gv, init_val);
                } else {
                    LLVMSetInitializer(gv, LLVMConstNull(gt));
                }
                sv_map_set(&ctx.global_vars, lexer.str_dup(qname), gv);
            }
            if (k == nd_func_decl) {
                parser.func_decl* fd = (parser.func_decl*)decl;
                i8 qname[512];
                snprintf(qname, (u64)512, "%s__NS_%s", nd.name, fd.name);
                i8* orig_name = fd.name;
                fd.name = lexer.str_dup(qname);
                i8* saved_class = ctx.current_class_name;
                visit_func_decl(fd, ctx);
                ctx.current_class_name = saved_class;
                fd.name = orig_name;
            }
            if (k == nd_namespace_decl) {
                visit_namespace_decl((parser.namespace_decl*)decl, ctx);
            }
        }
        j = j + 1;
    }

    ctx.current_namespace = saved_ns;
}

// ---- Extern C block ----

void visit_extern_c_block(parser.extern_c_block* blk, ir_context* ctx) {
    i32 i = 0;
    while (i < blk.decls_len) {
        parser.ast_node* decl = blk.decls[i];
        if (decl != (parser.ast_node*)0 && decl.kind == nd_func_decl) {
            parser.func_decl* fd = (parser.func_decl*)decl;
            fd.is_extern_c = true;
            visit_func_decl_prototype(fd, ctx);
        }
        i = i + 1;
    }
}

// ---- Top-level dispatch ----

void visit_top_level_decl(parser.ast_node* node, ir_context* ctx) {
    if (node == (parser.ast_node*)0) { return; }
    i32 kind = node.kind;

    if (kind == nd_struct_decl) {
        visit_struct_decl((parser.struct_decl*)node, ctx);
        return;
    }
    if (kind == nd_enum_decl) {
        visit_enum_decl((parser.enum_decl*)node, ctx);
        return;
    }
    if (kind == nd_typedef_decl) {
        visit_typedef_decl((parser.typedef_decl*)node, ctx);
        return;
    }
    if (kind == nd_func_decl) {
        visit_func_decl_prototype((parser.func_decl*)node, ctx);
        return;
    }
    if (kind == nd_var_decl) {
        parser.var_decl* vd = (parser.var_decl*)node;
        if (vd.is_sta) { return; }  // compile-time only
        i8* gt = llvm_type_of(vd.type, ctx);
        i8* gv = LLVMAddGlobal(ctx.llvm_mod, gt, vd.name);
        i8* init_v = (i8*)0;
        if (vd.has_init) {
            init_v = visit_expr(vd.init, ctx);
            // Coerce constant initializer to match global type (e.g. i64 literal → i32).
            // Extract the numeric value and recreate with correct type.
            if (init_v != (i8*)0 && gt != (i8*)0 && LLVMTypeOf(init_v) != gt) {
                i32 ik = LLVMGetTypeKind(LLVMTypeOf(init_v));
                i32 gk = LLVMGetTypeKind(gt);
                if (ik == LLVMIntegerTypeKind && gk == LLVMIntegerTypeKind) {
                    i64 raw = LLVMConstIntGetSExtValue(init_v);
                    init_v = LLVMConstInt(gt, (u64)raw, 1);
                }
            }
        }
        if (init_v != (i8*)0) {
            LLVMSetInitializer(gv, init_v);
        } else {
            LLVMSetInitializer(gv, LLVMConstNull(gt));
        }
        sv_map_set(&ctx.global_vars, vd.name, gv);
        return;
    }
    if (kind == nd_namespace_decl) {
        visit_namespace_decl((parser.namespace_decl*)node, ctx);
        return;
    }
    if (kind == nd_extern_c_block) {
        visit_extern_c_block((parser.extern_c_block*)node, ctx);
        return;
    }
}

// ---- Program ----

void visit_program(parser.program_node* prog, ir_context* ctx) {
    // Pass 1: register all types and function prototypes
    i32 i = 0;
    while (i < prog.decls_len) {
        visit_top_level_decl(prog.decls[i], ctx);
        i = i + 1;
    }

    // Pass 2: emit function bodies
    i32 j = 0;
    while (j < prog.decls_len) {
        parser.ast_node* decl = prog.decls[j];
        if (decl != (parser.ast_node*)0 && decl.kind == nd_func_decl) {
            visit_func_decl((parser.func_decl*)decl, ctx);
        }
        j = j + 1;
    }
}

} // namespace ir
