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
    sm.is_union = d.is_union;
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

    if (d.is_union && nfields > 0) {
        // For unions: compute max field byte size and use { [max x i8] } as body.
        u64 max_size = 0;
        i32 ui = 0;
        while (ui < nfields) {
            u64 fsz = llvm_type_byte_size(field_types_arr[ui]);
            if (fsz > max_size) { max_size = fsz; }
            ui = ui + 1;
        }
        if (max_size == 0) { max_size = 1; }
        i8* i8t = LLVMInt8TypeInContext(ctx.llvm_ctx);
        i8* arr_t = LLVMArrayType(i8t, (u32)max_size);
        i8* union_body[1];
        union_body[0] = arr_t;
        LLVMStructSetBody(struct_t, union_body, 1, 0);
    } else {
        LLVMStructSetBody(struct_t, field_types_arr, nfields, 0);
    }
    free((i8*)field_types_arr);

    struct_meta_vec_push(&ctx.struct_meta_tbl, sm);
}

// ---- Enum declaration ----

void visit_enum_decl(parser.enum_decl* d, ir_context* ctx) {
    i8* i32t = LLVMInt32TypeInContext(ctx.llvm_ctx);

    // For ADT enums: compute max payload size across all variants
    u64 max_payload = 0;
    if (d.is_adt && d.variant_kinds != (i32*)0) {
        i32 vi = 0;
        while (vi < d.variants_len) {
            i32 vkind = d.variant_kinds[vi];
            i32 fc = (d.variant_field_counts != (i32*)0) ? d.variant_field_counts[vi] : 0;
            if ((vkind == 1 || vkind == 2 || vkind == 3) && fc > 0 && d.variant_field_type_flat != (i8**)0) {
                u64 variant_size = 0;
                i32 fi = 0;
                while (fi < fc) {
                    parser.type_node* ft = (parser.type_node*)d.variant_field_type_flat[vi * 8 + fi];
                    i8* lt = (ft != (parser.type_node*)0) ? llvm_type_of(ft, ctx) : i32t;
                    u64 fsz = llvm_type_byte_size(lt);
                    // Align to 8 bytes
                    variant_size = variant_size + ((fsz + 7) & ~(u64)7);
                    fi = fi + 1;
                }
                if (variant_size > max_payload) { max_payload = variant_size; }
            }
            vi = vi + 1;
        }
    }

    // Create ADT enum struct type: { i32 tag, [max_payload x i8] }
    i8* adt_struct_t = (i8*)0;
    i8* adt_arr_t = (i8*)0;
    if (d.is_adt && max_payload > 0) {
        i8* i8t = LLVMInt8TypeInContext(ctx.llvm_ctx);
        adt_arr_t = LLVMArrayType(i8t, (i32)max_payload);
        i8* flds[2]; flds[0] = i32t; flds[1] = adt_arr_t;
        adt_struct_t = LLVMStructCreateNamed(ctx.llvm_ctx, d.name);
        LLVMStructSetBody(adt_struct_t, flds, 2, 0);
        st_map_set(&ctx.struct_types, d.name, adt_struct_t);
        // Register field metadata: __tag (index 0) and __payload (index 1)
        struct_meta sm;
        sm.name = lexer.str_dup(d.name);
        name_list_init(&sm.field_names);
        type_list_init(&sm.field_types);
        bool_list_init(&sm.field_unsigned);
        type_list_init(&sm.field_pointee);
        sm.is_union = false;
        name_list_push(&sm.field_names, (i8*)"__tag");
        type_list_push(&sm.field_types, i32t);
        bool_list_push(&sm.field_unsigned, false);
        type_list_push(&sm.field_pointee, (i8*)0);
        name_list_push(&sm.field_names, (i8*)"__payload");
        type_list_push(&sm.field_types, adt_arr_t);
        bool_list_push(&sm.field_unsigned, false);
        type_list_push(&sm.field_pointee, (i8*)0);
        struct_meta_vec_push(&ctx.struct_meta_tbl, sm);
        // Register this enum_decl for ADT constructor lookup
        sv_map_set(&ctx.adt_enum_decls, d.name, (i8*)d);
    }

    // Register per-variant field metadata for named/istruc variants
    if (d.is_adt && d.variant_kinds != (i32*)0) {
        i32 vi = 0;
        while (vi < d.variants_len) {
            i32 vkind = d.variant_kinds[vi];
            i32 fc = (d.variant_field_counts != (i32*)0) ? d.variant_field_counts[vi] : 0;
            if ((vkind == 2 || vkind == 3) && fc > 0 && d.variant_field_type_flat != (i8**)0) {
                i8 vqname[512];
                snprintf(vqname, (u64)512, "%s__%s", d.name, d.variant_names[vi]);
                struct_meta vsm;
                vsm.name = lexer.str_dup(vqname);
                name_list_init(&vsm.field_names);
                type_list_init(&vsm.field_types);
                bool_list_init(&vsm.field_unsigned);
                type_list_init(&vsm.field_pointee);
                vsm.is_union = false;
                i32 fi = 0;
                while (fi < fc) {
                    parser.type_node* ft = (parser.type_node*)d.variant_field_type_flat[vi * 8 + fi];
                    i8* flt = (ft != (parser.type_node*)0) ? llvm_type_of(ft, ctx) : i32t;
                    i8* fname = (d.variant_field_names_flat != (i8**)0) ? d.variant_field_names_flat[vi * 8 + fi] : (i8*)0;
                    if (fname == (i8*)0) { i8 tmp[16]; snprintf(tmp, (u64)16, "_f%d", fi); fname = lexer.str_dup(tmp); }
                    name_list_push(&vsm.field_names, fname);
                    type_list_push(&vsm.field_types, flt);
                    bool_list_push(&vsm.field_unsigned, false);
                    type_list_push(&vsm.field_pointee, (i8*)0);
                    fi = fi + 1;
                }
                struct_meta_vec_push(&ctx.struct_meta_tbl, vsm);
            }
            vi = vi + 1;
        }
    }

    // Emit methods stored on ADT istruc/named_struct variants
    if (d.is_adt && d.variant_kinds != (i32*)0 && d.variant_method_flat != (i8**)0) {
        i32 vi = 0;
        while (vi < d.variants_len) {
            i32 vkind = d.variant_kinds[vi];
            i32 mc = (d.variant_method_counts != (i32*)0) ? d.variant_method_counts[vi] : 0;
            if ((vkind == 2 || vkind == 3) && mc > 0) {
                i8* vname = d.variant_names[vi];
                // Register variant name as alias for the enum struct so
                // "const fatal* self" resolves to the enum type
                i8* enum_st = st_map_get(&ctx.struct_types, d.name);
                if (enum_st != (i8*)0) {
                    st_map_set(&ctx.struct_types, vname, enum_st);
                }
                i32 mi = 0;
                while (mi < mc) {
                    parser.func_decl* mfd = (parser.func_decl*)d.variant_method_flat[vi * 8 + mi];
                    if (mfd != (parser.func_decl*)0) {
                        i8 mt_name[512];
                        snprintf(mt_name, (u64)512, "%s__NS_%s__MT_%s", d.name, vname, mfd.name);
                        i8* saved_name = mfd.name;
                        mfd.name = lexer.str_dup(mt_name);
                        visit_func_decl_prototype(mfd, ctx);
                        visit_func_decl(mfd, ctx);
                        mfd.name = saved_name;
                    }
                    mi = mi + 1;
                }
            }
            vi = vi + 1;
        }
    }

    // Register variant tag constants
    i64 next_val = 0;
    i32 i = 0;
    while (i < d.variants_len) {
        if (d.variant_has_val[i]) { next_val = d.variant_vals[i]; }
        i8 qname[512];
        snprintf(qname, (u64)512, "%s__%s", d.name, d.variant_names[i]);
        i8* gv = LLVMAddGlobal(ctx.llvm_mod, i32t, qname);
        LLVMSetInitializer(gv, LLVMConstInt(i32t, (u64)next_val, 1));
        LLVMSetGlobalConstant(gv, 1);
        LLVMSetLinkage(gv, LLVMInternalLinkage);
        sv_map_set(&ctx.global_vars, qname, gv);
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
    // Generic functions: save for lazy monomorphization, don't compile now
    if (fd.type_params_len > 0) {
        i8* gname = ir_func_name(fd);
        sv_map_set(&ctx.generic_funcs, gname, (i8*)fd);
        return;
    }

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
    if (fd.type_params_len > 0) { return; } // handled by monomorphization
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
        i8* pname = p.name != (i8*)0 ? p.name : "arg";
        ctx_declare_local(ctx, pname, alloca, pt, deref_t, puns);
        if (p.type != (parser.type_node*)0 && p.type.is_func_ptr) {
            i8* pfn_ty = llvm_func_type_of(p.type, ctx);
            if (pfn_ty != (i8*)0) { ctx_declare_local_func_type(ctx, pname, pfn_ty); }
        }
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
            if (k == nd_struct_decl)   {
                parser.struct_decl* sd = (parser.struct_decl*)decl;
                visit_struct_decl(sd, ctx);
                // Also register the struct under the namespace-qualified name so that
                // external code can look it up as "ns__NS_StructName".
                i8 ns_sname[512];
                snprintf(ns_sname, (u64)512, "%s__NS_%s", nd.name, sd.name);
                i8* bare_st = st_map_get(&ctx.struct_types, sd.name);
                if (bare_st != (i8*)0) {
                    st_map_set(&ctx.struct_types, lexer.str_dup(ns_sname), bare_st);
                    // For nested istruc (e.g. shapes { istruc Circle }), also register
                    // as "shapes__NS_Circle" so qualified type "shapes.Circle" resolves.
                    if (saved_ns != (i8*)0) {
                        i8 fq_sname[512];
                        snprintf(fq_sname, (u64)512, "%s__NS_%s", saved_ns, sd.name);
                        st_map_set(&ctx.struct_types, lexer.str_dup(fq_sname), bare_st);
                    }
                }
            }
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
    // Pass 1: register prototypes
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
    // Pass 2: emit bodies for functions that have them
    i32 j = 0;
    while (j < blk.decls_len) {
        parser.ast_node* decl = blk.decls[j];
        if (decl != (parser.ast_node*)0 && decl.kind == nd_func_decl) {
            parser.func_decl* fd = (parser.func_decl*)decl;
            if (fd.has_body) {
                fd.is_extern_c = true;
                visit_func_decl(fd, ctx);
            }
        }
        j = j + 1;
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
        if (is_unsigned_type_node(vd.type)) {
            sb_map_set(&ctx.global_var_unsigned, vd.name, true);
        }
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
