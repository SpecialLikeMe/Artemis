// Declaration IR generation for the Artemis self-hosting compiler.

namespace ir {

// Forward declaration
fn visit_top_level_decl(node: *parser.ast_node, ctx: *ir_context) void;

// ---- Struct declaration ----

fn visit_struct_decl(d: *parser.struct_decl, ctx: *ir_context) void {
    // Idempotency guard: if the struct is already registered, skip re-creation
    // to avoid LLVM creating a duplicate named type (e.g. "soa_layout.1").
    if (st_map_get(&ctx.struct_types, d.name) != (i8*)0) { return; }

    // Create an opaque named struct and register it
    let mut struct_t: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, d.name);
    st_map_set(&ctx.struct_types, d.name, struct_t);

    // Build field type arrays
    let mut nfields: i32= d.fields_len;
    let mut field_types_arr: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)nfields);

    let mut sm: struct_meta;
    sm.name = d.name;
    sm.is_union = d.is_union;
    sm.is_istruc = ctx.current_ns_is_istruc;
    name_list_init(&sm.field_names);
    type_list_init(&sm.field_types);
    bool_list_init(&sm.field_unsigned);
    type_list_init(&sm.field_pointee);
    name_list_init(&sm.field_pointee_names);

    let mut i: i32= 0;
    while (i < nfields) {
        let mut f: *parser.var_decl= d.fields[i];
        let mut ft: *i8= llvm_type_of(f.type, ctx);
        field_types_arr[i] = ft;
        name_list_push(&sm.field_names, f.name);
        type_list_push(&sm.field_types, ft);
        bool_list_push(&sm.field_unsigned, is_unsigned_type_node(f.type));

        let mut pointee_t: *i8= (i8*)0;
        let mut pointee_n: *i8= (i8*)0;
        if (f.type != (parser.type_node*)0 && f.type.pointer_depth > 0 && f.type.name != (i8*)0) {
            let mut stripped: parser.type_node;
            stripped = *f.type;
            stripped.pointer_depth = stripped.pointer_depth - 1;
            pointee_t = llvm_type_of(&stripped, ctx);
            // Store fully-qualified pointee name for forward-reference resolution at use time
            if (ctx.current_namespace != (i8*)0) {
                let mut qn: [512]i8;
                snprintf(qn, (u64)512, "%s__NS_%s", ctx.current_namespace, f.type.name);
                pointee_n = lexer.str_dup(qn);
            } else {
                pointee_n = f.type.name;
            }
        } else if (f.type != (parser.type_node*)0 && f.type.is_func_ptr) {
            // Store the bare LLVM function type so visit_call can use it for
            // indirect calls through struct function pointer fields.
            pointee_t = llvm_func_type_of(f.type, ctx);
        } else if (f.type != (parser.type_node*)0 && f.type.pointer_depth > 0) {
            let mut stripped2: parser.type_node;
            stripped2 = *f.type;
            stripped2.pointer_depth = stripped2.pointer_depth - 1;
            pointee_t = llvm_type_of(&stripped2, ctx);
        }
        type_list_push(&sm.field_pointee, pointee_t);
        name_list_push(&sm.field_pointee_names, pointee_n);
        i = i + 1;
    }

    if (d.is_union && nfields > 0) {
        // For unions: compute max field byte size and use { [max x i8] } as body.
        let mut max_size: u64= 0;
        let mut ui: i32= 0;
        while (ui < nfields) {
            let mut fsz: u64= llvm_type_byte_size(field_types_arr[ui]);
            if (fsz > max_size) { max_size = fsz; }
            ui = ui + 1;
        }
        if (max_size == 0) { max_size = 1; }
        let mut i8t: *i8= LLVMInt8TypeInContext(ctx.llvm_ctx);
        let mut arr_t: *i8= LLVMArrayType2(i8t, (u64)max_size);
        let mut union_body: [1]*i8;
        union_body[0] = arr_t;
        LLVMStructSetBody(struct_t, union_body, 1, 0);
    } else if (nfields == 0 && ctx.current_ns_is_interface) {
        // Interface with no fields: leave opaque so visit_namespace_decl can set
        // the fat-pointer body { ptr data, ptr vtable } once method names are known.
    } else {
        LLVMStructSetBody(struct_t, field_types_arr, nfields, 0);
    }
    arc_free((i8*)field_types_arr);

    struct_meta_vec_push(&ctx.struct_meta_tbl, sm);
}

// ---- Enum declaration ----

fn visit_enum_decl(d: *parser.enum_decl, ctx: *ir_context) void {
    // Idempotency: skip if this type was pre-registered (e.g. type_info by ensure_typeinfo_types)
    if (d.is_adt) {
        if (sv_map_get(&ctx.adt_enum_decls, d.name) != (i8*)0) { return; }
    }

    let mut i32t: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);

    // For ADT enums: compute max payload size across all variants
    let mut max_payload: u64= 0;
    if (d.is_adt && d.variant_kinds != (i32*)0) {
        let mut vi: i32= 0;
        while (vi < d.variants_len) {
            let mut vkind: i32= d.variant_kinds[vi];
            let mut fc: i32= (d.variant_field_counts != (i32*)0) ? d.variant_field_counts[vi] : 0;
            if ((vkind == 1 || vkind == 2 || vkind == 3) && fc > 0 && d.variant_field_type_flat != (i8**)0) {
                let mut variant_size: u64= 0;
                let mut fi: i32= 0;
                while (fi < fc) {
                    let mut ft: *parser.type_node= (parser.type_node*)d.variant_field_type_flat[vi * 8 + fi];
                    let mut lt: *i8= (ft != (parser.type_node*)0) ? llvm_type_of(ft, ctx) : i32t;
                    let mut fsz: u64= llvm_type_byte_size(lt);
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
    let mut adt_struct_t: *i8= (i8*)0;
    let mut adt_arr_t: *i8= (i8*)0;
    if (d.is_adt && max_payload > 0) {
        let mut i8t: *i8= LLVMInt8TypeInContext(ctx.llvm_ctx);
        adt_arr_t = LLVMArrayType2(i8t, (u64)max_payload);
        let mut flds: [2]*i8; flds[0] = i32t; flds[1] = adt_arr_t;
        adt_struct_t = LLVMStructCreateNamed(ctx.llvm_ctx, d.name);
        LLVMStructSetBody(adt_struct_t, flds, 2, 0);
        st_map_set(&ctx.struct_types, d.name, adt_struct_t);
        // Register field metadata: __tag (index 0) and __payload (index 1)
        let mut sm: struct_meta;
        sm.name = lexer.str_dup(d.name);
        name_list_init(&sm.field_names);
        type_list_init(&sm.field_types);
        bool_list_init(&sm.field_unsigned);
        type_list_init(&sm.field_pointee);
        name_list_init(&sm.field_pointee_names);
        sm.is_union = false;
        sm.is_istruc = false;
        name_list_push(&sm.field_names, (i8*)"__tag");
        type_list_push(&sm.field_types, i32t);
        bool_list_push(&sm.field_unsigned, false);
        type_list_push(&sm.field_pointee, (i8*)0);
        name_list_push(&sm.field_pointee_names, (i8*)0);
        name_list_push(&sm.field_names, (i8*)"__payload");
        type_list_push(&sm.field_types, adt_arr_t);
        bool_list_push(&sm.field_unsigned, false);
        type_list_push(&sm.field_pointee, (i8*)0);
        name_list_push(&sm.field_pointee_names, (i8*)0);
        struct_meta_vec_push(&ctx.struct_meta_tbl, sm);
        // Register this enum_decl for ADT constructor lookup
        sv_map_set(&ctx.adt_enum_decls, d.name, (i8*)d);
    }

    // Register per-variant field metadata for named/istruc variants
    if (d.is_adt && d.variant_kinds != (i32*)0) {
        let mut vi: i32= 0;
        while (vi < d.variants_len) {
            let mut vkind: i32= d.variant_kinds[vi];
            let mut fc: i32= (d.variant_field_counts != (i32*)0) ? d.variant_field_counts[vi] : 0;
            if ((vkind == 1 || vkind == 2 || vkind == 3) && fc > 0 && d.variant_field_type_flat != (i8**)0) {
                let mut vqname: [512]i8;
                snprintf(vqname, (u64)512, "%s__%s", d.name, d.variant_names[vi]);
                // Create LLVM struct type for this variant's payload fields
                // so that emit_pat_match can load the payload as the variant struct type.
                let mut vfts: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)fc);
                let mut fi0: i32= 0;
                while (fi0 < fc) {
                    let mut ft0: *parser.type_node= (parser.type_node*)d.variant_field_type_flat[vi * 8 + fi0];
                    vfts[fi0] = (ft0 != (parser.type_node*)0) ? llvm_type_of(ft0, ctx) : i32t;
                    fi0 = fi0 + 1;
                }
                let mut vstruct_ty: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, lexer.str_dup(vqname));
                LLVMStructSetBody(vstruct_ty, vfts, (u32)fc, 0);
                arc_free((i8*)vfts);
                st_map_set(&ctx.struct_types, lexer.str_dup(vqname), vstruct_ty);
                // Register struct_meta for field access in emit_pat_match
                let mut vsm: struct_meta;
                vsm.name = lexer.str_dup(vqname);
                name_list_init(&vsm.field_names);
                type_list_init(&vsm.field_types);
                bool_list_init(&vsm.field_unsigned);
                type_list_init(&vsm.field_pointee);
                name_list_init(&vsm.field_pointee_names);
                vsm.is_union = false;
                vsm.is_istruc = false;
                let mut fi: i32= 0;
                while (fi < fc) {
                    let mut ft: *parser.type_node= (parser.type_node*)d.variant_field_type_flat[vi * 8 + fi];
                    let mut flt: *i8= (ft != (parser.type_node*)0) ? llvm_type_of(ft, ctx) : i32t;
                    let mut fname: *i8= (d.variant_field_names_flat != (i8**)0) ? d.variant_field_names_flat[vi * 8 + fi] : (i8*)0;
                    if (fname == (i8*)0) { let mut tmp: [16]i8; snprintf(tmp, (u64)16, "_f%d", fi); fname = lexer.str_dup(tmp); }
                    name_list_push(&vsm.field_names, fname);
                    type_list_push(&vsm.field_types, flt);
                    bool_list_push(&vsm.field_unsigned, false);
                    type_list_push(&vsm.field_pointee, (i8*)0);
                    name_list_push(&vsm.field_pointee_names, (i8*)0);
                    fi = fi + 1;
                }
                struct_meta_vec_push(&ctx.struct_meta_tbl, vsm);
            }
            vi = vi + 1;
        }
    }

    // Emit methods stored on ADT istruc/named_struct variants
    if (d.is_adt && d.variant_kinds != (i32*)0 && d.variant_method_flat != (i8**)0) {
        let mut vi: i32= 0;
        while (vi < d.variants_len) {
            let mut vkind: i32= d.variant_kinds[vi];
            let mut mc: i32= (d.variant_method_counts != (i32*)0) ? d.variant_method_counts[vi] : 0;
            if ((vkind == 2 || vkind == 3) && mc > 0) {
                let mut vname: *i8= d.variant_names[vi];
                // Register variant name as alias for the enum struct so
                // "const fatal* self" resolves to the enum type
                let mut enum_st: *i8= st_map_get(&ctx.struct_types, d.name);
                if (enum_st != (i8*)0) {
                    st_map_set(&ctx.struct_types, vname, enum_st);
                }
                let mut mi: i32= 0;
                while (mi < mc) {
                    let mut mfd: *parser.func_decl= (parser.func_decl*)d.variant_method_flat[vi * 8 + mi];
                    if (mfd != (parser.func_decl*)0) {
                        let mut mt_name: [512]i8;
                        snprintf(mt_name, (u64)512, "%s__NS_%s__MT_%s", d.name, vname, mfd.name);
                        let mut saved_name: *i8= mfd.name;
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
    let mut next_val: i64= 0;
    let mut i: i32= 0;
    while (i < d.variants_len) {
        if (d.variant_has_val[i]) { next_val = d.variant_vals[i]; }
        let mut qname: [512]i8;
        snprintf(qname, (u64)512, "%s__%s", d.name, d.variant_names[i]);
        let mut gv: *i8= LLVMAddGlobal(ctx.llvm_mod, i32t, qname);
        LLVMSetInitializer(gv, LLVMConstInt(i32t, (u64)next_val, 1));
        LLVMSetGlobalConstant(gv, 1);
        LLVMSetLinkage(gv, LLVMInternalLinkage);
        sv_map_set(&ctx.global_vars, lexer.str_dup(qname), gv);
        sv_map_set(&ctx.global_vars, d.variant_names[i], gv);
        // Also register with __NS_ separator so `EnumName.variant` resolves via member-access chain
        let mut ns_qname: [512]i8;
        snprintf(ns_qname, (u64)512, "%s__NS_%s", d.name, d.variant_names[i]);
        sv_map_set(&ctx.global_vars, lexer.str_dup(ns_qname), gv);
        next_val = next_val + 1;
        i = i + 1;
    }
    // Register all enums (including simple non-ADT ones) for @typeinfo lookups.
    if (!sv_map_has(&ctx.adt_enum_decls, d.name)) {
        sv_map_set(&ctx.adt_enum_decls, d.name, (i8*)d);
    }
}

// ---- Typedef declaration ----

fn visit_typedef_decl(d: *parser.typedef_decl, ctx: *ir_context) void {
    // `using ns_name;` — namespace import
    if (d.is_namespace_using) {
        if (d.ns_using_name != (i8*)0) { ctx_add_using_ns(ctx, d.ns_using_name); }
        return;
    }
    if (d.target == (parser.type_node*)0 || d.name == (i8*)0) { return; }

    // Check if target is a struct type
    let mut target_is_struct: bool= false;
    if (!d.target.is_primitive && d.target.name != (i8*)0 && d.target.pointer_depth == 0) {
        let mut found: *i8= st_map_get(&ctx.struct_types, d.target.name);
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

// Returns true if fd is an istruc method that needs an implicit self pointer prepended.
// Conditions: in istruc namespace, not static, and first param is NOT a ptr-to-struct.
fn func_needs_implicit_self(fd: *parser.func_decl, ctx: *ir_context) bool {
    if (!ctx.current_ns_is_istruc) { return false; }
    if (fd.is_static) { return false; }
    // If no params at all → implicit self
    if (fd.params_len == 0 || fd.params == (parser.param_decl*)0) { return true; }
    // Check if first param is a pointer to the struct type (explicit self)
    let mut fp: *parser.type_node= fd.params[0].type;
    if (fp == (parser.type_node*)0) { return true; }
    if (fp.is_primitive) { return true; }
    if (fp.name == (i8*)0 || ctx.current_class_name == (i8*)0) {
        if (fp.pointer_depth <= 0) { return true; }
        return true;
    }
    // Exact match (non-generic) → explicit self (ptr or value)
    if (strcmp(fp.name, ctx.current_class_name) == 0) { return false; }
    // Monomorphized case: current_class_name starts with fp.name + "__G_"
    // e.g. fp.name="Pair", current_class_name="Pair__G_i32"
    let mut base_len: i32= (i32)strlen(fp.name);
    if (strncmp(ctx.current_class_name, fp.name, (u64)base_len) == 0) {
        let mut suffix: *i8= ctx.current_class_name + base_len;
        if (suffix[0] == '_' && suffix[1] == '_' && suffix[2] == 'G' && suffix[3] == '_') {
            return false; // explicit self (generic monomorphized)
        }
    }
    return true;
}

fn visit_func_decl_prototype(fd: *parser.func_decl, ctx: *ir_context) void {
    // Generic functions: save for lazy monomorphization, don't compile now
    if (fd.type_params_len > 0) {
        let mut gname: *i8= ir_func_name(fd);
        sv_map_set(&ctx.generic_funcs, gname, (i8*)fd);
        return;
    }

    // anytype functions: defer compilation until call site with concrete types
    let mut has_anytype_proto: bool= false;
    let mut atpi: i32= 0;
    while (atpi < fd.params_len) {
        if (fd.params[atpi].type != (parser.type_node*)0 && fd.params[atpi].type.is_anytype) {
            has_anytype_proto = true;
        }
        atpi = atpi + 1;
    }
    if (has_anytype_proto && !ctx.in_anytype_mono) {
        let mut at_name: *i8= ir_func_name(fd);
        sv_map_set(&ctx.anytype_funcs, at_name, (i8*)fd);
        return;
    }

    let mut fn_name: *i8= ir_func_name(fd);

    // Build return type
    let mut ret_t: *i8= (i8*)0;
    if (fd.ret_type != (parser.type_node*)0) {
        ret_t = llvm_type_of(fd.ret_type, ctx);
    }
    if (ret_t == (i8*)0) {
        ret_t = LLVMVoidTypeInContext(ctx.llvm_ctx);
    }
    // Error-union return type fixup:
    //   !void  → i32 (0=ok, non-zero=error)   [existing ABI, backward compat]
    //   !T     → { i32, T }                    [new: field 0 = is_err, field 1 = value]
    if (fd.is_error_union) {
        if (LLVMGetTypeKind(ret_t) == LLVMVoidTypeKind) {
            ret_t = LLVMInt32TypeInContext(ctx.llvm_ctx);
        } else {
            let mut eu_flds: [2]*i8;
            eu_flds[0] = LLVMInt32TypeInContext(ctx.llvm_ctx);
            eu_flds[1] = ret_t;
            ret_t = LLVMStructTypeInContext(ctx.llvm_ctx, eu_flds, 2, 0);
        }
    }

    // Detect implicit self: istruc method whose first param is NOT a ptr-to-struct
    let mut implicit_self: bool= func_needs_implicit_self(fd, ctx);
    let mut self_offset: i32= implicit_self ? 1 : 0;

    // Build parameter types (with optional implicit self ptr prepended)
    let mut nparams: i32= fd.params_len + self_offset;
    let mut param_types: **i8= (i8**)0;
    if (nparams > 0) {
        param_types = (i8**)arc_malloc(sizeof(i8*) * (u64)nparams);
        if (implicit_self) {
            param_types[0] = LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
        }
        let mut i: i32= 0;
        while (i < fd.params_len) {
            let mut pt: *i8= llvm_type_of(fd.params[i].type, ctx);
            if (pt == (i8*)0) { pt = LLVMVoidTypeInContext(ctx.llvm_ctx); }
            // anytype: override with bound concrete type during monomorphization
            if (fd.params[i].type != (parser.type_node*)0 && fd.params[i].type.is_anytype &&
                    fd.params[i].name != (i8*)0 && ctx.in_anytype_mono) {
                let mut bound_pt: *i8= st_map_get(&ctx.anytype_param_bindings, fd.params[i].name);
                if (bound_pt != (i8*)0) { pt = bound_pt; }
            }
            param_types[i + self_offset] = pt;
            i = i + 1;
        }
    }
    let mut variadic: i32= fd.is_variadic ? 1 : 0;
    let mut fn_type: *i8= LLVMFunctionType(ret_t, param_types, nparams, variadic);
    if (param_types != (i8**)0) { arc_free((i8*)param_types); }

    // Check if already declared (extern prototype)
    let mut existing: *i8= sv_map_get(&ctx.global_funcs, fn_name);
    let mut fn_ref: *i8= (i8*)0;
    if (existing != (i8*)0) {
        fn_ref = existing;
    } else {
        fn_ref = LLVMAddFunction(ctx.llvm_mod, fn_name, fn_type);
        // Non-pub functions with a body get internal linkage
        // Exceptions: main (entry point), extern-only declarations
        let mut is_main: bool= (strcmp(fd.name, "main") == 0);
        if (!fd.is_pub && fd.has_body && !fd.is_extern_c && !is_main) {
            LLVMSetLinkage(fn_ref, LLVMInternalLinkage);
        }
    }

    sv_map_set(&ctx.global_funcs,           fn_name, fn_ref);
    st_map_set(&ctx.global_func_types,      fn_name, fn_type);
    let mut ret_uns: bool= is_unsigned_type_node(fd.ret_type);
    sb_map_set(&ctx.global_func_ret_unsigned, fn_name, ret_uns);
    sv_map_set(&ctx.global_func_decls, fn_name, (i8*)fd);
}

// ---- Function body (pass 2) ----

fn visit_func_decl(fd: *parser.func_decl, ctx: *ir_context) void {
    if (!fd.has_body) { return; }
    if (fd.type_params_len > 0) { return; } // handled by monomorphization
    // anytype functions: compiled on demand by visit_call, not during pass 2
    let mut has_anytype_decl: bool= false;
    let mut atdi: i32= 0;
    while (atdi < fd.params_len) {
        if (fd.params[atdi].type != (parser.type_node*)0 && fd.params[atdi].type.is_anytype) {
            has_anytype_decl = true;
        }
        atdi = atdi + 1;
    }
    if (has_anytype_decl && !ctx.in_anytype_mono && sv_map_get(&ctx.anytype_funcs, ir_func_name(fd)) != (i8*)0) { return; }
    let mut fn_name: *i8= ir_func_name(fd);
    let mut fn_ref: *i8= sv_map_get(&ctx.global_funcs, fn_name);
    let mut fn_type: *i8= st_map_get(&ctx.global_func_types, fn_name);
    if (fn_ref == (i8*)0 || fn_type == (i8*)0) { return; }

    let mut entry_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "entry");
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, entry_bb);

    ctx.current_func      = fn_ref;
    ctx.current_func_type = fn_type;

    let mut ret_t: *i8= (i8*)0;
    if (fd.ret_type != (parser.type_node*)0) {
        ret_t = llvm_type_of(fd.ret_type, ctx);
    }
    // Error-union: mirror the prototype ABI fixup
    ctx.current_func_eu_is_value = false;
    ctx.current_eu_value_type    = (i8*)0;
    if (fd.is_error_union) {
        if (ret_t == (i8*)0 || LLVMGetTypeKind(ret_t) == LLVMVoidTypeKind) {
            // !void → i32 (existing)
            ret_t = LLVMInt32TypeInContext(ctx.llvm_ctx);
        } else {
            // !T → { i32, T }
            ctx.current_func_eu_is_value = true;
            ctx.current_eu_value_type    = ret_t;
            let mut eu_flds2: [2]*i8;
            eu_flds2[0] = LLVMInt32TypeInContext(ctx.llvm_ctx);
            eu_flds2[1] = ret_t;
            ret_t = LLVMStructTypeInContext(ctx.llvm_ctx, eu_flds2, 2, 0);
        }
    }
    ctx.current_ret_type = ret_t;
    ctx.current_func_is_error_union = fd.is_error_union;

    // Push function scope
    ctx_push_scope(ctx);

    // Detect implicit self (same logic as prototype)
    let mut impl_self: bool= func_needs_implicit_self(fd, ctx);
    let mut self_offset: i32= impl_self ? 1 : 0;

    // Bind implicit self pointer (param 0) as `self` in scope
    if (impl_self) {
        let mut self_val: *i8= LLVMGetParam(fn_ref, 0);
        let mut ptr_t: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
        let mut self_alloca: *i8= LLVMBuildAlloca(ctx.llvm_builder, ptr_t, "self");
        LLVMBuildStore(ctx.llvm_builder, self_val, self_alloca);
        // Determine deref type from struct name
        let mut deref_t: *i8= (ctx.current_class_name != (i8*)0) ? st_map_get(&ctx.struct_types, ctx.current_class_name) : (i8*)0;
        ctx_declare_local(ctx, "self", self_alloca, ptr_t, deref_t, false);
    }

    // Alloca for each parameter
    let mut i: i32= 0;
    while (i < fd.params_len) {
        let mut p: parser.param_decl= fd.params[i];
        let mut param_val: *i8= LLVMGetParam(fn_ref, i + self_offset);
        let mut pt: *i8= llvm_type_of(p.type, ctx);
        // anytype: override with bound concrete type if available
        if (p.type != (parser.type_node*)0 && p.type.is_anytype && p.name != (i8*)0) {
            let mut bound_at: *i8= st_map_get(&ctx.anytype_param_bindings, p.name);
            if (bound_at != (i8*)0) { pt = bound_at; }
        }
        let mut alloca: *i8= LLVMBuildAlloca(ctx.llvm_builder, pt, p.name != (i8*)0 ? p.name : "arg");
        LLVMBuildStore(ctx.llvm_builder, param_val, alloca);

        let mut deref_t: *i8= (i8*)0;
        if (p.type != (parser.type_node*)0 && p.type.is_interface && p.type.name != (i8*)0) {
            // Interface parameter: ptr pointing to the interface struct.
            // Set deref_t so field access (f.z) can GEP through the pointer.
            if (p.type.type_args_len > 0) {
                // Generic interface: compute monomorphized name e.g. bar__G_i32
                deref_t = ir_get_or_monomorphize_generic_class(p.type, ctx);
            }
            if (deref_t == (i8*)0) {
                deref_t = st_map_get(&ctx.struct_types, p.type.name);
            }
        } else if (p.type != (parser.type_node*)0 && p.type.pointer_depth > 0) {
            let mut stripped: parser.type_node;
            stripped = *p.type;
            stripped.pointer_depth = stripped.pointer_depth - 1;
            deref_t = llvm_type_of(&stripped, ctx);
        }
        let mut puns: bool= is_unsigned_type_node(p.type);
        let mut pname: *i8= p.name != (i8*)0 ? p.name : "arg";
        ctx_declare_local(ctx, pname, alloca, pt, deref_t, puns);
        if (p.type != (parser.type_node*)0 && p.type.is_func_ptr) {
            let mut pfn_ty: *i8= llvm_func_type_of(p.type, ctx);
            if (pfn_ty != (i8*)0) { ctx_declare_local_func_type(ctx, pname, pfn_ty); }
        }
        i = i + 1;
    }

    // Emit body
    if (fd.body != (i8*)0) {
        let mut blk: *parser.block_stmt= (parser.block_stmt*)fd.body;
        visit_block_stmt(blk, ctx);
    }

    // Ensure terminator
    if (!ctx_is_terminated(ctx)) {
        let mut rv: *i8= ctx.current_ret_type;
        // !void error-union: falling off the end is implicit success (return 0)
        let mut eu_void: bool= fd.is_error_union && (
            fd.ret_type == (parser.type_node*)0 ||
            (fd.ret_type.has_prim && fd.ret_type.prim == (i32)void_t));
        if (rv == (i8*)0 || LLVMGetTypeKind(rv) == LLVMVoidTypeKind) {
            LLVMBuildRetVoid(ctx.llvm_builder);
        } else if (eu_void) {
            LLVMBuildRet(ctx.llvm_builder, LLVMConstInt(LLVMInt32TypeInContext(ctx.llvm_ctx), 0, 0));
        } else if (ctx.current_func_eu_is_value) {
            // !T error-union: falling off end = implicit success { 0, undef }
            let mut i32t_fb: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);
            let mut eu_fb: *i8= LLVMGetUndef(rv);
            eu_fb = LLVMBuildInsertValue(ctx.llvm_builder, eu_fb, LLVMConstInt(i32t_fb, 0, 0), 0, "eu_ok_fb");
            eu_fb = LLVMBuildInsertValue(ctx.llvm_builder, eu_fb, LLVMGetUndef(ctx.current_eu_value_type), 1, "eu_val_fb");
            LLVMBuildRet(ctx.llvm_builder, eu_fb);
        } else {
            // Non-void function fell off end — compile error
            let mut fname: *i8= fd.name != (i8*)0 ? fd.name : "<anonymous>";
            printf("error: function '%s' may not return on all paths (line %d)\n", fname, (i32)fd.line);
            ctx.had_error = true;
            LLVMBuildRet(ctx.llvm_builder, LLVMConstNull(rv));
        }
    }

    ctx_pop_scope(ctx);
    ctx.current_func      = (i8*)0;
    ctx.current_func_type        = (i8*)0;
    ctx.current_ret_type         = (i8*)0;
    ctx.current_func_eu_is_value = false;
    ctx.current_eu_value_type    = (i8*)0;
}

// ---- Generic class monomorphization ----

fn ir_get_or_monomorphize_generic_class(t: *parser.type_node, ctx: *ir_context) *i8 {
    if (t == (parser.type_node*)0 || t.type_args_len == 0 || t.name == (i8*)0) {
        return (i8*)0;
    }
    let mut base_name: *i8= t.name;

    // Build mono_name: base__G_<arg1>_<arg2>...
    let mut mono_name: [512]i8;
    let mut mn_off: i32= snprintf(mono_name, (u64)512, "%s__G", base_name);
    let mut tai: i32= 0;
    while (tai < t.type_args_len) {
        let mut ta: *parser.type_node= (parser.type_node*)t.type_args[tai];
        // Key on the resolved LLVM type. Mangling the source spelling would make
        // `Box<T>` (as written inside Box's own methods) collide across every
        // instantiation, so the second one would reuse the first one's struct.
        let mut ta_llvm_k: *i8= llvm_type_of(ta, ctx);
        let mut ta_m: *i8= (ta_llvm_k != (i8*)0) ? mangle_llvm_type(ta_llvm_k) : mangle_type(ta);
        let mut tl: i32= (i32)strlen(ta_m);
        if (mn_off + tl + 2 < 510) {
            mono_name[mn_off] = '_';
            mn_off = mn_off + 1;
            let mut ci: i32= 0;
            while (ci < tl) { mono_name[mn_off + ci] = ta_m[ci]; ci = ci + 1; }
            mn_off = mn_off + tl;
            mono_name[mn_off] = 0;
        }
        tai = tai + 1;
    }
    let mut mono_name_dup: *i8= lexer.str_dup(mono_name);

    // Already instantiated?
    let mut existing: *i8= st_map_get(&ctx.struct_types, mono_name_dup);
    if (existing != (i8*)0) { return existing; }

    // Look up generic class registry
    let mut gnd_ptr: *i8= sv_map_get(&ctx.generic_classes, base_name);
    if (gnd_ptr == (i8*)0) { return (i8*)0; }
    let mut gnd: *parser.namespace_decl= (parser.namespace_decl*)gnd_ptr;

    // Find struct_decl or enum_decl child
    let mut sd: *parser.struct_decl= (parser.struct_decl*)0;
    let mut ged: *parser.enum_decl= (parser.enum_decl*)0;
    let mut di: i32= 0;
    while (di < gnd.decls_len) {
        let mut gnd_di: *parser.ast_node= gnd.decls[di];
        if (gnd_di != (parser.ast_node*)0 && gnd_di.kind == nd_struct_decl) {
            sd = (parser.struct_decl*)gnd_di;
            break;
        }
        if (gnd_di != (parser.ast_node*)0 && gnd_di.kind == nd_enum_decl) {
            ged = (parser.enum_decl*)gnd_di;
            break;
        }
        di = di + 1;
    }

    // Generic enum: emit via visit_enum_decl with monomorphized name
    if (ged != (parser.enum_decl*)0 && sd == (parser.struct_decl*)0) {
        let mut saved_ged_name: *i8= ged.name;
        ged.name = mono_name_dup;
        visit_enum_decl(ged, ctx);
        ged.name = saved_ged_name;
        // Register mono name as struct type alias for type resolution (enums resolve to i32)
        let mut i32t2: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);
        st_map_set(&ctx.struct_types, mono_name_dup, i32t2);
        return i32t2;
    }

    // Save existing bindings before overwriting — a nested generic (e.g. map_node<K,V>)
    // monomorphized inside an outer generic (e.g. map<i32,i32>) shares type-param names.
    // Without save/restore, the cleanup below would clobber the outer bindings.
    let mut saved_tp_count: i32= gnd.type_params_len < 16 ? gnd.type_params_len : 16;
    let mut saved_tp_vals: [16]*i8;
    let mut stpi: i32= 0;
    while (stpi < saved_tp_count) {
        saved_tp_vals[stpi] = st_map_get(&ctx.type_param_bindings, gnd.type_params[stpi]);
        stpi = stpi + 1;
    }
    let mut saved_cls_binding: *i8= st_map_get(&ctx.type_param_bindings, gnd.name);

    // Bind type params and class name itself (so `vector*` self resolves to mono_struct*)
    // We bind before creating the struct so circular refs use a placeholder.
    // Class name is bound AFTER the struct is created (see below).
    let mut tpi: i32= 0;
    while (tpi < gnd.type_params_len && tpi < t.type_args_len) {
        let mut ta: *parser.type_node= (parser.type_node*)t.type_args[tpi];
        let mut ta_llvm: *i8= llvm_type_of(ta, ctx);
        st_map_set(&ctx.type_param_bindings, gnd.type_params[tpi], ta_llvm);
        tpi = tpi + 1;
    }

    // Create named LLVM struct (register early to handle recursive refs)
    let mut mono_struct: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, mono_name_dup);
    st_map_set(&ctx.struct_types, mono_name_dup, mono_struct);
    // Bind class short name so `vector*` self params resolve to mono_struct*
    st_map_set(&ctx.type_param_bindings, gnd.name, mono_struct);

    // Build field types and struct_meta
    let mut sm: struct_meta;
    sm.name = mono_name_dup;
    sm.is_union = gnd.is_union;
    sm.is_istruc = gnd.is_istruc;
    name_list_init(&sm.field_names);
    type_list_init(&sm.field_types);
    bool_list_init(&sm.field_unsigned);
    type_list_init(&sm.field_pointee);
    name_list_init(&sm.field_pointee_names);

    if (sd != (parser.struct_decl*)0 && sd.fields_len > 0) {
        let mut nfields: i32= sd.fields_len;
        let mut fts: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)nfields);
        let mut fi: i32= 0;
        while (fi < nfields) {
            let mut f: *parser.var_decl= sd.fields[fi];
            let mut ft: *i8= llvm_type_of(f.type, ctx);
            fts[fi] = ft;
            name_list_push(&sm.field_names, f.name);
            type_list_push(&sm.field_types, ft);
            bool_list_push(&sm.field_unsigned, is_unsigned_type_node(f.type));
            let mut pointee_t: *i8= (i8*)0;
            let mut pointee_n: *i8= (i8*)0;
            if (f.type != (parser.type_node*)0 && f.type.pointer_depth > 0 && f.type.name != (i8*)0) {
                let mut stripped: parser.type_node;
                stripped = *f.type;
                stripped.pointer_depth = stripped.pointer_depth - 1;
                pointee_t = llvm_type_of(&stripped, ctx);
                // Store fully-qualified pointee name for forward-reference resolution at use time
                if (ctx.current_namespace != (i8*)0) {
                    let mut qn2: [512]i8;
                    snprintf(qn2, (u64)512, "%s__NS_%s", ctx.current_namespace, f.type.name);
                    pointee_n = lexer.str_dup(qn2);
                } else {
                    pointee_n = f.type.name;
                }
            } else if (f.type != (parser.type_node*)0 && f.type.pointer_depth > 0) {
                let mut stripped3: parser.type_node;
                stripped3 = *f.type;
                stripped3.pointer_depth = stripped3.pointer_depth - 1;
                pointee_t = llvm_type_of(&stripped3, ctx);
            }
            type_list_push(&sm.field_pointee, pointee_t);
            name_list_push(&sm.field_pointee_names, pointee_n);
            fi = fi + 1;
        }
        if (gnd.is_union) {
            let mut max_size: u64= 0;
            let mut ui: i32= 0;
            while (ui < nfields) {
                let mut fsz: u64= llvm_type_byte_size(fts[ui]);
                if (fsz > max_size) { max_size = fsz; }
                ui = ui + 1;
            }
            if (max_size == 0) { max_size = 1; }
            let mut i8t: *i8= LLVMInt8TypeInContext(ctx.llvm_ctx);
            let mut arr_t: *i8= LLVMArrayType2(i8t, (u64)max_size);
            let mut union_body: [1]*i8;
            union_body[0] = arr_t;
            LLVMStructSetBody(mono_struct, union_body, 1, 0);
        } else {
            LLVMStructSetBody(mono_struct, fts, nfields, 0);
        }
        arc_free((i8*)fts);
    } else {
        let mut empty: **i8= (i8**)arc_malloc(sizeof(i8*));
        LLVMStructSetBody(mono_struct, empty, 0, 0);
        arc_free((i8*)empty);
    }
    struct_meta_vec_push(&ctx.struct_meta_tbl, sm);

    // Save builder position — monomorphization may be triggered mid-function.
    let mut saved_insert_bb: *i8= LLVMGetInsertBlock(ctx.llvm_builder);

    // Emit methods in a namespace named after the monomorphized type
    let mut saved_ns: *i8= ctx.current_namespace;
    ctx.current_namespace = mono_name_dup;
    let mut saved_cls: *i8= ctx.current_class_name;
    ctx.current_class_name = mono_name_dup;

    // Pre-pass: assign qualified names to every func_decl in gnd.decls.
    // Overloading is not supported � duplicate function names emit an error.
    // Forward declarations (no body) always get the base name and don't count as duplicates.
    let mut ol_qnames: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)(gnd.decls_len + 1));
    let mut seen_names: [64]*i8;
    let mut seen_len: i32= 0;
    let mut pre: i32= 0;
    while (pre < gnd.decls_len) {
        let mut pd: *parser.ast_node= gnd.decls[pre];
        if (pd != (parser.ast_node*)0 && pd.kind == nd_func_decl) {
            let mut pfd: *parser.func_decl= (parser.func_decl*)pd;
            let mut base: [512]i8;
            snprintf(base, (u64)512, "%s__NS_%s", mono_name_dup, pfd.name);
            ol_qnames[pre] = lexer.str_dup(base);
            if (pfd.has_body) {
                let mut already_seen: bool= false;
                let mut si: i32= 0;
                while (si < seen_len && !already_seen) {
                    if (strcmp(seen_names[si], base) == 0) { already_seen = true; }
                    si = si + 1;
                }
                if (already_seen) {
                    printf("error: duplicate function name '%s'; overloading is not supported
", pfd.name);
                    ctx.had_error = true;
                } else if (seen_len < 64) {
                    seen_names[seen_len] = lexer.str_dup(base);
                    seen_len = seen_len + 1;
                }
            }
        } else {
            ol_qnames[pre] = (i8*)0;
        }
        pre = pre + 1;
    }

    // Pass 1: prototypes
    let mut mi: i32= 0;
    while (mi < gnd.decls_len) {
        let mut decl: *parser.ast_node= gnd.decls[mi];
        if (decl != (parser.ast_node*)0 && decl.kind == nd_func_decl) {
            let mut fd: *parser.func_decl= (parser.func_decl*)decl;
            let mut qn: *i8= ol_qnames[mi];
            if (qn != (i8*)0) {
                let mut on: *i8= fd.name; let mut om: *i8= fd.mangled_name; let mut otl: i32= fd.type_params_len;
                fd.name = qn; fd.mangled_name = (i8*)0; fd.type_params_len = 0;
                visit_func_decl_prototype(fd, ctx);
                fd.name = on; fd.mangled_name = om; fd.type_params_len = otl;
            }
        }
        mi = mi + 1;
    }

    // Pass 2: bodies
    let mut mj: i32= 0;
    while (mj < gnd.decls_len) {
        let mut decl: *parser.ast_node= gnd.decls[mj];
        if (decl != (parser.ast_node*)0 && decl.kind == nd_func_decl) {
            let mut fd: *parser.func_decl= (parser.func_decl*)decl;
            let mut qn: *i8= ol_qnames[mj];
            if (qn != (i8*)0) {
                let mut on: *i8= fd.name; let mut om: *i8= fd.mangled_name; let mut otl: i32= fd.type_params_len;
                let mut sf: *i8= ctx.current_func; let mut sft: *i8= ctx.current_func_type;
                let mut srt: *i8= ctx.current_ret_type;
                let mut seu: bool= ctx.current_func_is_error_union;
                let mut seut: *i8= ctx.current_error_union_type;
                fd.name = qn; fd.mangled_name = (i8*)0; fd.type_params_len = 0;
                visit_func_decl(fd, ctx);
                fd.name = on; fd.mangled_name = om; fd.type_params_len = otl;
                ctx.current_func = sf; ctx.current_func_type = sft;
                ctx.current_ret_type = srt;
                ctx.current_func_is_error_union = seu;
                ctx.current_error_union_type = seut;
            }
        }
        mj = mj + 1;
    }

    arc_free((i8*)ol_qnames);

    // Restore saved bindings (don't blank-clear — outer mono scope may use the same names).
    tpi = 0;
    while (tpi < saved_tp_count) {
        st_map_set(&ctx.type_param_bindings, gnd.type_params[tpi], saved_tp_vals[tpi]);
        tpi = tpi + 1;
    }
    st_map_set(&ctx.type_param_bindings, gnd.name, saved_cls_binding);

    ctx.current_namespace = saved_ns;
    ctx.current_class_name = saved_cls;

    // Restore builder position in case we were mid-function when triggered.
    if (saved_insert_bb != (i8*)0) {
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, saved_insert_bb);
    }
    return mono_struct;
}

// ---- memstr fat-pointer support ----

// Ensure __vtable__ (5 slots) and memstr/memstr fat-pointer struct types are created.
// If the stdlib has already defined these via Arc struct/istruc declarations, reuse
// the existing LLVM named structs rather than creating duplicates.
// Vtable layout: { ptr mmap, ptr rsmap, ptr rmap, ptr free, ptr destroy }
fn ensure_memstr_types(ctx: *ir_context) void {
    if (ctx.memstr_fat_type != (i8*)0) { return; }
    let mut ptr_t: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);

    // __vtable__ — 5-slot function-pointer table.
    ctx.memstr_vtable_type = LLVMGetTypeByName2(ctx.llvm_ctx, "__vtable__");
    if (ctx.memstr_vtable_type == (i8*)0) {
        let mut vfields: [5]*i8;
        vfields[0] = ptr_t; vfields[1] = ptr_t; vfields[2] = ptr_t;
        vfields[3] = ptr_t; vfields[4] = ptr_t;
        ctx.memstr_vtable_type = LLVMStructCreateNamed(ctx.llvm_ctx, "__vtable__");
        LLVMStructSetBody(ctx.memstr_vtable_type, vfields, 5, 0);
    }
    st_map_set(&ctx.struct_types, lexer.str_dup("__vtable__"), ctx.memstr_vtable_type);
    // struct_meta for __vtable__ field-name access (mmap/rsmap/rmap/free/destroy).
    let mut svm: struct_meta;
    svm.name = "__vtable__"; svm.is_union = false; svm.is_istruc = false;
    name_list_init(&svm.field_names); type_list_init(&svm.field_types);
    bool_list_init(&svm.field_unsigned); type_list_init(&svm.field_pointee);
    name_list_push(&svm.field_names, "mmap");    type_list_push(&svm.field_types, ptr_t); bool_list_push(&svm.field_unsigned, false); type_list_push(&svm.field_pointee, (i8*)0);
    name_list_push(&svm.field_names, "rsmap");   type_list_push(&svm.field_types, ptr_t); bool_list_push(&svm.field_unsigned, false); type_list_push(&svm.field_pointee, (i8*)0);
    name_list_push(&svm.field_names, "rmap");    type_list_push(&svm.field_types, ptr_t); bool_list_push(&svm.field_unsigned, false); type_list_push(&svm.field_pointee, (i8*)0);
    name_list_push(&svm.field_names, "free");    type_list_push(&svm.field_types, ptr_t); bool_list_push(&svm.field_unsigned, false); type_list_push(&svm.field_pointee, (i8*)0);
    name_list_push(&svm.field_names, "destroy"); type_list_push(&svm.field_types, ptr_t); bool_list_push(&svm.field_unsigned, false); type_list_push(&svm.field_pointee, (i8*)0);
    struct_meta_vec_push(&ctx.struct_meta_tbl, svm);

    // memstr fat pointer — { ptr data, ptr vtable }.
    ctx.memstr_fat_type = LLVMGetTypeByName2(ctx.llvm_ctx, "memstr");
    if (ctx.memstr_fat_type == (i8*)0) {
        ctx.memstr_fat_type = LLVMGetTypeByName2(ctx.llvm_ctx, "__memstr_fat__");
    }
    if (ctx.memstr_fat_type == (i8*)0) {
        let mut ffields: [2]*i8;
        ffields[0] = ptr_t; ffields[1] = ptr_t;
        ctx.memstr_fat_type = LLVMStructCreateNamed(ctx.llvm_ctx, "memstr");
        LLVMStructSetBody(ctx.memstr_fat_type, ffields, 2, 0);
    }
    st_map_set(&ctx.struct_types, lexer.str_dup("memstr"), ctx.memstr_fat_type);
    st_map_set(&ctx.struct_types, lexer.str_dup("__memstr_fat__"), ctx.memstr_fat_type);
    // struct_meta for memstr field-name access (ptr/vtable).
    // memstr is now an istruc (is_istruc = true) with field name "ptr" (not "data").
    let mut smm: struct_meta;
    smm.name = "memstr"; smm.is_union = false; smm.is_istruc = true;
    name_list_init(&smm.field_names); type_list_init(&smm.field_types);
    bool_list_init(&smm.field_unsigned); type_list_init(&smm.field_pointee);
    name_list_push(&smm.field_names, "ptr");    type_list_push(&smm.field_types, ptr_t); bool_list_push(&smm.field_unsigned, false); type_list_push(&smm.field_pointee, (i8*)0);
    name_list_push(&smm.field_names, "vtable"); type_list_push(&smm.field_types, ptr_t); bool_list_push(&smm.field_unsigned, false); type_list_push(&smm.field_pointee, ctx.memstr_vtable_type);
    struct_meta_vec_push(&ctx.struct_meta_tbl, smm);
}

// Emit a vtable global for a memstr class.
//   @ClassName__vtable__ = constant { ptr x5 } { ptr @mmap, ptr @rsmap, ptr @rmap, ptr @free, ptr @destroy }
// All 5 slots are populated by looking up ClassName__NS_<method>.
fn emit_memstr_vtable(nd: *parser.namespace_decl, qual_name: *i8, ctx: *ir_context) void {
    ensure_memstr_types(ctx);
    let mut vtname: [512]i8;
    snprintf(vtname, (u64)512, "%s__vtable__", nd.name);
    // 5-slot vtable: mmap, rsmap, rmap, free, destroy
    // Try qualified name first (e.g. std__NS_arena__NS_mmap), then simple name (arena__NS_mmap).
    let mut slots: [5]*i8;
    let mut methods: [5]*i8;
    methods[0] = "mmap";    methods[1] = "rsmap"; methods[2] = "rmap";
    methods[3] = "free";    methods[4] = "destroy";
    let mut ptr_t: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
    let mut si: i32= 0;
    while (si < 5) {
        let mut fn_ref: *i8= (i8*)0;
        // Try qualified name first
        let mut qbuf: [512]i8;
        snprintf(qbuf, (u64)512, "%s__NS_%s", qual_name, methods[si]);
        fn_ref = LLVMGetNamedFunction(ctx.llvm_mod, qbuf);
        // Fall back to simple name
        if (fn_ref == (i8*)0) {
            let mut sbuf: [512]i8;
            snprintf(sbuf, (u64)512, "%s__NS_%s", nd.name, methods[si]);
            fn_ref = LLVMGetNamedFunction(ctx.llvm_mod, sbuf);
        }
        // destroy slot also accepts 'deinit' as canonical name
        if (fn_ref == (i8*)0 && si == 4) {
            snprintf(qbuf, (u64)512, "%s__NS_deinit", qual_name);
            fn_ref = LLVMGetNamedFunction(ctx.llvm_mod, qbuf);
            if (fn_ref == (i8*)0) {
                let mut sbuf2: [512]i8;
                snprintf(sbuf2, (u64)512, "%s__NS_deinit", nd.name);
                fn_ref = LLVMGetNamedFunction(ctx.llvm_mod, sbuf2);
            }
        }
        if (fn_ref != (i8*)0) { slots[si] = fn_ref; }
        else               { slots[si] = LLVMConstPointerNull(ptr_t); }
        si = si + 1;
    }
    let mut vtinit: *i8= LLVMConstNamedStruct(ctx.memstr_vtable_type, slots, 5);
    let mut vtglobal: *i8= LLVMAddGlobal(ctx.llvm_mod, ctx.memstr_vtable_type, vtname);
    LLVMSetInitializer(vtglobal, vtinit);
    LLVMSetGlobalConstant(vtglobal, 1);
    sv_map_set(&ctx.memstr_vtables, lexer.str_dup(nd.name), vtglobal);
    sv_map_set(&ctx.memstr_vtables, lexer.str_dup(qual_name), vtglobal);
}

// ---- Comptime constant expression evaluator ----

// Evaluate a compile-time constant expression to an i64.
// Returns true on success (stores result in *out), false if not evaluable.
fn constexpr_eval_expr(e: *parser.expr_node, ctx: *ir_context, out: *i64) bool {
    if (e == (parser.expr_node*)0) { return false; }
    let mut k: i32= e.kind;
    if (k == ek_int_lit) { *out = e.int_val; return true; }
    if (k == ek_bool_lit) { *out = e.bool_val ? (i64)1 : (i64)0; return true; }
    if (k == ek_identifier && e.str_val != (i8*)0) {
        let mut cv: *i8= sv_map_get(&ctx.constexpr_int_vals_map, e.str_val);
        if (cv != (i8*)0) { *out = (i64)cv; return true; }
        if (ctx.current_namespace != (i8*)0) {
            let mut fqn: [512]i8;
            snprintf(fqn, (u64)512, "%s__NS_%s", ctx.current_namespace, e.str_val);
            cv = sv_map_get(&ctx.constexpr_int_vals_map, fqn);
            if (cv != (i8*)0) { *out = (i64)cv; return true; }
        }
        return false;
    }
    if (k == ek_binary) {
        let mut lv: i64= 0; let mut rv2: i64= 0;
        if (!constexpr_eval_expr(e.lhs, ctx, &lv)) { return false; }
        if (!constexpr_eval_expr(e.rhs, ctx, &rv2)) { return false; }
        let mut op: i32= e.bop;
        if (op == bop_add) { *out = lv + rv2; return true; }
        if (op == bop_sub) { *out = lv - rv2; return true; }
        if (op == bop_mul) { *out = lv * rv2; return true; }
        if (op == bop_div) { if (rv2 == (i64)0) { return false; } *out = lv / rv2; return true; }
        if (op == bop_mod) { if (rv2 == (i64)0) { return false; } *out = lv % rv2; return true; }
        if (op == bop_bit_and) { *out = lv & rv2; return true; }
        if (op == bop_bit_or)  { *out = lv | rv2; return true; }
        if (op == bop_bit_xor) { *out = lv ^ rv2; return true; }
        if (op == bop_shl) { *out = lv << rv2; return true; }
        if (op == bop_shr) { *out = (i64)((u64)lv >> (u64)rv2); return true; }
        if (op == bop_eq)  { *out = (lv == rv2) ? (i64)1 : (i64)0; return true; }
        if (op == bop_ne)  { *out = (lv != rv2) ? (i64)1 : (i64)0; return true; }
        if (op == bop_lt)  { *out = (lv <  rv2) ? (i64)1 : (i64)0; return true; }
        if (op == bop_gt)  { *out = (lv >  rv2) ? (i64)1 : (i64)0; return true; }
        if (op == bop_lte) { *out = (lv <= rv2) ? (i64)1 : (i64)0; return true; }
        if (op == bop_gte) { *out = (lv >= rv2) ? (i64)1 : (i64)0; return true; }
        return false;
    }
    if (k == ek_unary) {
        let mut v: i64= 0;
        if (!constexpr_eval_expr(e.operand, ctx, &v)) { return false; }
        if (e.uop == uop_neg) { *out = -v; return true; }
        if (e.uop == uop_bit_not) { *out = ~v; return true; }
        if (e.uop == uop_log_not) { *out = (v == (i64)0) ? (i64)1 : (i64)0; return true; }
        return false;
    }
    if (k == ek_cast || k == ek_cast_as) { return constexpr_eval_expr(e.operand, ctx, out); }
    if (k == ek_match_expr) { return false; }
    return false;
}

// Register a comptime variable's value in constexpr_int_vals_map under several names.
fn register_constexpr(pvd: *parser.var_decl, ctx: *ir_context) void {
    if (pvd == (parser.var_decl*)0 || !pvd.is_constexpr) { return; }
    if (!pvd.has_init || pvd.init == (parser.expr_node*)0) { return; }
    if (pvd.name == (i8*)0) { return; }
    let mut iv: i64= 0;
    if (!constexpr_eval_expr(pvd.init, ctx, &iv)) { return; }
    sv_map_set(&ctx.constexpr_int_vals_map, lexer.str_dup(pvd.name), (i8*)iv);
    if (ctx.current_namespace != (i8*)0) {
        let mut qn: [512]i8;
        snprintf(qn, (u64)512, "%s__NS_%s", ctx.current_namespace, pvd.name);
        sv_map_set(&ctx.constexpr_int_vals_map, lexer.str_dup(qn), (i8*)iv);
    }
}

// ---- Namespace ----

fn visit_namespace_decl(nd: *parser.namespace_decl, ctx: *ir_context) void {
    let mut saved_ns: *i8= ctx.current_namespace;
    let mut saved_cls: *i8= ctx.current_class_name;
    let mut saved_is_istruc: bool= ctx.current_ns_is_istruc;
    let mut saved_is_interface: bool= ctx.current_ns_is_interface;
    let mut ns_buf: [256]i8;
    if (saved_ns != (i8*)0) {
        snprintf(ns_buf, (u64)256, "%s__NS_%s", saved_ns, nd.name);
    } else {
        snprintf(ns_buf, (u64)256, "%s", nd.name);
    }
    ctx.current_namespace       = lexer.str_dup(ns_buf);
    ctx.current_ns_is_istruc    = nd.is_istruc;
    ctx.current_ns_is_interface = nd.is_interface;
    if (nd.is_istruc) {
        ctx.current_class_name = nd.name;
        // Register for field-default lookup during construction
        sv_map_set(&ctx.istruc_decls, lexer.str_dup(nd.name), (i8*)nd);
        sv_map_set(&ctx.istruc_decls, lexer.str_dup(ns_buf), (i8*)nd);
    }

    // Generic class: register for later monomorphization, don't emit yet.
    if (nd.type_params_len > 0) {
        sv_map_set(&ctx.generic_classes, lexer.str_dup(ns_buf), (i8*)nd);
        // Also register under bare name for non-qualified lookup
        sv_map_set(&ctx.generic_classes, lexer.str_dup(nd.name), (i8*)nd);
        ctx.current_namespace       = saved_ns;
        ctx.current_class_name      = saved_cls;
        ctx.current_ns_is_istruc    = saved_is_istruc;
        ctx.current_ns_is_interface = saved_is_interface;
        return;
    }

    // Pre-pass: assign qualified names to every func_decl in nd.decls.
    // Overloading is not supported — duplicate function names emit an error.
    // Forward declarations (no body) always get the base name and don't count as duplicates.
    let mut ol_qnames: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)(nd.decls_len + 1));
    let mut seen_names: [64]*i8;
    let mut seen_len: i32= 0;
    let mut pre: i32= 0;
    while (pre < nd.decls_len) {
        let mut pd: *parser.ast_node= nd.decls[pre];
        if (pd != (parser.ast_node*)0 && pd.kind == nd_func_decl) {
            let mut pfd: *parser.func_decl= (parser.func_decl*)pd;
            let mut base: [512]i8;
            snprintf(base, (u64)512, "%s__NS_%s", nd.name, pfd.name);
            ol_qnames[pre] = lexer.str_dup(base);
            // Check for duplicate definitions (not forward declarations)
            if (pfd.has_body) {
                let mut already_seen: bool= false;
                let mut si: i32= 0;
                while (si < seen_len && !already_seen) {
                    if (strcmp(seen_names[si], base) == 0) { already_seen = true; }
                    si = si + 1;
                }
                if (already_seen) {
                    printf("error: duplicate function name '%s'; overloading is not supported\n", pfd.name);
                    ctx.had_error = true;
                } else if (seen_len < 64) {
                    seen_names[seen_len] = lexer.str_dup(base);
                    seen_len = seen_len + 1;
                }
            }
        } else {
            ol_qnames[pre] = (i8*)0;
        }
        pre = pre + 1;
    }

    // Pre-pass 0: populate constexpr_int_vals_map from comptime var_decls
    // Supports binary expressions and references to earlier comptime constants.
    let mut pre0: i32= 0;
    while (pre0 < nd.decls_len) {
        let mut pd0: *parser.ast_node= nd.decls[pre0];
        if (pd0 != (parser.ast_node*)0 && pd0.kind == nd_var_decl) {
            let mut pvd: *parser.var_decl= (parser.var_decl*)pd0;
            if (pvd.is_constexpr && pvd.has_init && pvd.init != (parser.expr_node*)0 && pvd.name != (i8*)0) {
                let mut iv: i64= 0;
                if (constexpr_eval_expr(pvd.init, ctx, &iv)) {
                    sv_map_set(&ctx.constexpr_int_vals_map, lexer.str_dup(pvd.name), (i8*)iv);
                    let mut pre_qn: [512]i8;
                    snprintf(pre_qn, (u64)512, "%s__NS_%s", nd.name, pvd.name);
                    sv_map_set(&ctx.constexpr_int_vals_map, lexer.str_dup(pre_qn), (i8*)iv);
                    if (saved_ns != (i8*)0) {
                        let mut pre_fq: [512]i8;
                        snprintf(pre_fq, (u64)512, "%s__NS_%s__NS_%s", saved_ns, nd.name, pvd.name);
                        sv_map_set(&ctx.constexpr_int_vals_map, lexer.str_dup(pre_fq), (i8*)iv);
                    }
                }
            }
        }
        pre0 = pre0 + 1;
    }

    // Pass 1: register types and prototypes
    let mut i: i32= 0;
    while (i < nd.decls_len) {
        let mut decl: *parser.ast_node= nd.decls[i];
        if (decl != (parser.ast_node*)0) {
            let mut k: i32= decl.kind;
            if (k == nd_struct_decl)   {
                let mut sd: *parser.struct_decl= (parser.struct_decl*)decl;
                visit_struct_decl(sd, ctx);
                // Also register the struct under the namespace-qualified name so that
                // external code can look it up as "ns__NS_StructName".
                let mut ns_sname: [512]i8;
                snprintf(ns_sname, (u64)512, "%s__NS_%s", nd.name, sd.name);
                let mut bare_st: *i8= st_map_get(&ctx.struct_types, sd.name);
                if (bare_st != (i8*)0) {
                    st_map_set(&ctx.struct_types, lexer.str_dup(ns_sname), bare_st);
                    // For nested istruc (e.g. shapes { istruc Circle }), also register
                    // as "shapes__NS_Circle" so qualified type "shapes.Circle" resolves.
                    if (saved_ns != (i8*)0) {
                        let mut fq_sname: [512]i8;
                        snprintf(fq_sname, (u64)512, "%s__NS_%s", saved_ns, sd.name);
                        st_map_set(&ctx.struct_types, lexer.str_dup(fq_sname), bare_st);
                        // Also register fully-qualified 3-level path:
                        // saved_ns__NS_nd.name__NS_sd.name (e.g. std__NS_typeinfo__NS_type_info)
                        let mut fq3_sname: [512]i8;
                        snprintf(fq3_sname, (u64)512, "%s__NS_%s__NS_%s", saved_ns, nd.name, sd.name);
                        st_map_set(&ctx.struct_types, lexer.str_dup(fq3_sname), bare_st);
                    }
                }
            }
            if (k == nd_enum_decl)     { visit_enum_decl((parser.enum_decl*)decl, ctx); }
            if (k == nd_typedef_decl)  { visit_typedef_decl((parser.typedef_decl*)decl, ctx); }
            // istruc pre-registration: istruc creates a namespace_decl whose first child
            // is a struct_decl. Register that struct NOW so that function prototypes later
            // in this same pass can resolve the struct type (e.g. make_soa return type).
            // Skip generic istructs (type_params_len > 0) — those are monomorphized on demand.
            if (k == nd_namespace_decl) {
                let mut inner_nd: *parser.namespace_decl= (parser.namespace_decl*)decl;
                if (inner_nd.type_params_len == 0 && inner_nd.decls_len > 0) {
                    let mut first_child: *parser.ast_node= inner_nd.decls[0];
                    if (first_child != (parser.ast_node*)0 && first_child.kind == nd_struct_decl) {
                        let mut inner_sd: *parser.struct_decl= (parser.struct_decl*)first_child;
                        visit_struct_decl(inner_sd, ctx);
                        let mut inner_st: *i8= st_map_get(&ctx.struct_types, inner_sd.name);
                        if (inner_st != (i8*)0) {
                            let mut inner_qn: [512]i8;
                            snprintf(inner_qn, (u64)512, "%s__NS_%s", nd.name, inner_sd.name);
                            st_map_set(&ctx.struct_types, lexer.str_dup(inner_qn), inner_st);
                            if (saved_ns != (i8*)0) {
                                let mut outer_qn: [512]i8;
                                snprintf(outer_qn, (u64)512, "%s__NS_%s", saved_ns, inner_sd.name);
                                st_map_set(&ctx.struct_types, lexer.str_dup(outer_qn), inner_st);
                                let mut full3_qn: [512]i8;
                                snprintf(full3_qn, (u64)512, "%s__NS_%s__NS_%s", saved_ns, nd.name, inner_sd.name);
                                st_map_set(&ctx.struct_types, lexer.str_dup(full3_qn), inner_st);
                            }
                        }
                    }
                }
            }
            if (k == nd_func_decl) {
                let mut fd: *parser.func_decl= (parser.func_decl*)decl;
                let mut qname_dup: *i8= ol_qnames[i];
                if (qname_dup != (i8*)0) {
                    let mut orig_name: *i8= fd.name;
                    // For extern C declarations, keep the bare C name so the linker
                    // finds the real symbol. Register under qualified name separately.
                    if (!fd.is_extern_c) {
                        fd.name = qname_dup;
                    }
                    visit_func_decl_prototype(fd, ctx);
                    // If extern C: also map the qualified name → same LLVM function
                    if (fd.is_extern_c) {
                        let mut fn_p: *i8= sv_map_get(&ctx.global_funcs, orig_name);
                        let mut ft_p: *i8= st_map_get(&ctx.global_func_types, orig_name);
                        if (fn_p != (i8*)0) { sv_map_set(&ctx.global_funcs, lexer.str_dup(qname_dup), fn_p); }
                        if (ft_p != (i8*)0) { st_map_set(&ctx.global_func_types, lexer.str_dup(qname_dup), ft_p); }
                    }
                    sv_map_set(&ctx.global_funcs, fd.name, sv_map_get(&ctx.global_funcs, fd.name));
                    // Register FQ alias for multi-level namespace access
                    if (saved_ns != (i8*)0) {
                        let mut fq_proto: [512]i8;
                        snprintf(fq_proto, (u64)512, "%s__NS_%s", ctx.current_namespace, orig_name);
                        let mut fn_p: *i8= sv_map_get(&ctx.global_funcs, fd.is_extern_c ? orig_name : qname_dup);
                        let mut ft_p: *i8= st_map_get(&ctx.global_func_types, fd.is_extern_c ? orig_name : qname_dup);
                        if (fn_p != (i8*)0) { sv_map_set(&ctx.global_funcs, lexer.str_dup(fq_proto), fn_p); }
                        if (ft_p != (i8*)0) { st_map_set(&ctx.global_func_types, lexer.str_dup(fq_proto), ft_p); }
                    }
                    fd.name = orig_name;
                }
            }
        }
        i = i + 1;
    }

    // Pass 2: emit bodies
    let mut j: i32= 0;
    while (j < nd.decls_len) {
        let mut decl: *parser.ast_node= nd.decls[j];
        if (decl != (parser.ast_node*)0) {
            let mut k: i32= decl.kind;
            if (k == nd_var_decl)  {
                // Global variable in namespace
                let mut vd: *parser.var_decl= (parser.var_decl*)decl;
                let mut qname: [512]i8;
                // Static istruc members have already been mangled to TYPENAME__static_FIELD;
                // emit them with the bare mangled name, not namespace-prefixed.
                if (vd.is_static) {
                    snprintf(qname, (u64)512, "%s", vd.name);
                } else {
                    snprintf(qname, (u64)512, "%s__NS_%s", nd.name, vd.name);
                }
                let mut gt: *i8= llvm_type_of(vd.type, ctx);
                let mut gv: *i8= LLVMAddGlobal(ctx.llvm_mod, gt, qname);
                let mut init_val: *i8= (i8*)0;
                if (vd.has_init) {
                    init_val = visit_expr(vd.init, ctx);
                    if (init_val != (i8*)0 && gt != (i8*)0 && LLVMTypeOf(init_val) != gt) {
                        let mut ik: i32= LLVMGetTypeKind(LLVMTypeOf(init_val));
                        let mut gk: i32= LLVMGetTypeKind(gt);
                        if (ik == LLVMIntegerTypeKind && gk == LLVMIntegerTypeKind) {
                            let mut raw: i64= LLVMConstIntGetSExtValue(init_val);
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
                // For static members, also register an __NS_ alias so "Counter.total"
                // (→ Counter__NS_total) resolves when used inside or outside the namespace.
                // vd.name is "Counter__static_field"; nd.name is "Counter".
                if (vd.is_static) {
                    let mut cls_len: i32= (i32)strlen(nd.name);
                    let mut skip: i32= cls_len + 9; // skip "CLASSNAME__static_"
                    let mut vn_len: i32= (i32)strlen(vd.name);
                    if (vn_len > skip) {
                        let mut ns_alias: [512]i8;
                        snprintf(ns_alias, (u64)512, "%s__NS_%s", nd.name, vd.name + skip);
                        sv_map_set(&ctx.global_vars, lexer.str_dup(ns_alias), gv);
                    }
                }
                // Also register under fully-qualified namespace name for multi-level access (e.g. std.hash.X)
                if (!vd.is_static && saved_ns != (i8*)0) {
                    let mut fq_vname: [512]i8;
                    snprintf(fq_vname, (u64)512, "%s__NS_%s", ctx.current_namespace, vd.name);
                    sv_map_set(&ctx.global_vars, lexer.str_dup(fq_vname), gv);
                }
            }
            if (k == nd_func_decl) {
                let mut fd: *parser.func_decl= (parser.func_decl*)decl;
                let mut qname_dup: *i8= ol_qnames[j];
                if (qname_dup != (i8*)0) {
                    let mut orig_name: *i8= fd.name;
                    fd.name = qname_dup;
                    visit_func_decl(fd, ctx);
                    fd.name = orig_name;
                    // Register FQ alias for multi-level namespace access (e.g. std.hash.func())
                    if (saved_ns != (i8*)0) {
                        let mut fq_fn: [512]i8;
                        snprintf(fq_fn, (u64)512, "%s__NS_%s", ctx.current_namespace, fd.name);
                        let mut fn_ref: *i8= sv_map_get(&ctx.global_funcs, qname_dup);
                        let mut ft_ref: *i8= st_map_get(&ctx.global_func_types, qname_dup);
                        if (fn_ref != (i8*)0) { sv_map_set(&ctx.global_funcs, lexer.str_dup(fq_fn), fn_ref); }
                        if (ft_ref != (i8*)0) { st_map_set(&ctx.global_func_types, lexer.str_dup(fq_fn), ft_ref); }
                    }
                }
            }
            if (k == nd_namespace_decl) {
                visit_namespace_decl((parser.namespace_decl*)decl, ctx);
            }
        }
        j = j + 1;
    }

    arc_free((i8*)ol_qnames);

    // memstr: emit vtable global after all method prototypes are registered.
    if (nd.is_memstr) {
        emit_memstr_vtable(nd, ns_buf, ctx);
    }

    // Interface fat-pointer vtable setup: after all methods registered,
    // change empty struct body to { ptr data, ptr vtable } and create vtable type.
    if (nd.is_interface) {
        let mut iface_methods: [64]*i8;
        let mut nm: i32= 0;
        let mut ipi: i32= 1; // skip struct_decl at index 0
        while (ipi < nd.decls_len && nm < 64) {
            let mut ipd: *parser.ast_node= nd.decls[ipi];
            if (ipd != (parser.ast_node*)0 && ipd.kind == nd_func_decl) {
                let mut ipfd: *parser.func_decl= (parser.func_decl*)ipd;
                if (strcmp(ipfd.name, "__construct__") != 0 &&
                    strcmp(ipfd.name, "__destruct__") != 0 &&
                    strncmp(ipfd.name, "operator", (u64)8) != 0) {
                    iface_methods[nm] = ipfd.name;
                    nm = nm + 1;
                }
            }
            ipi = ipi + 1;
        }
        if (nm > 0) {
            let mut ptr_t: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
            // Create vtable struct type: %IFaceName__vtable = { ptr, ptr, ... }
            let mut vtbl_sname: [256]i8;
            snprintf(vtbl_sname, (u64)256, "%s__vtable", nd.name);
            let mut vtbl_ty: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, lexer.str_dup(vtbl_sname));
            let mut vtbl_flds: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)nm);
            let mut vi: i32= 0;
            while (vi < nm) { vtbl_flds[vi] = ptr_t; vi = vi + 1; }
            LLVMStructSetBody(vtbl_ty, vtbl_flds, nm, 0);
            arc_free((i8*)vtbl_flds);
            st_map_set(&ctx.iface_vtable_types, lexer.str_dup(nd.name), vtbl_ty);
            // Set interface struct body to fat pointer { ptr data, ptr vtable }
            let mut iface_st: *i8= st_map_get(&ctx.struct_types, nd.name);
            if (iface_st != (i8*)0) {
                let mut fat_flds: [2]*i8;
                fat_flds[0] = ptr_t; fat_flds[1] = ptr_t;
                LLVMStructSetBody(iface_st, fat_flds, 2, 0);
            }
            // Update struct_meta
            let mut sm_iface: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, nd.name);
            if (sm_iface != (struct_meta*)0) {
                sm_iface.is_interface = true;
                name_list_init(&sm_iface.iface_method_names);
                let mut mnj: i32= 0;
                while (mnj < nm) {
                    name_list_push(&sm_iface.iface_method_names, iface_methods[mnj]);
                    mnj = mnj + 1;
                }
            }
        }
    }

    // Istruc with base interfaces: emit vtable constant globals
    if (nd.is_istruc && !nd.is_interface && nd.bases_len > 0) {
        let mut bi: i32= 0;
        while (bi < nd.bases_len) {
            let mut base_name: *i8= nd.bases[bi];
            if (base_name == (i8*)0) { bi = bi + 1; continue; }
            let mut vtbl_ty: *i8= st_map_get(&ctx.iface_vtable_types, base_name);
            if (vtbl_ty == (i8*)0) { bi = bi + 1; continue; }
            let mut base_sm: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, base_name);
            if (base_sm == (struct_meta*)0 || !base_sm.is_interface) { bi = bi + 1; continue; }
            let mut nmeth: i32= base_sm.iface_method_names.len;
            let mut slots: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)nmeth);
            let mut ptr_t: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
            let mut si: i32= 0;
            while (si < nmeth) {
                let mut mname: *i8= base_sm.iface_method_names.data[si];
                let mut fn_qn: [512]i8;
                snprintf(fn_qn, (u64)512, "%s__NS_%s", nd.name, mname);
                let mut fn_ref: *i8= sv_map_get(&ctx.global_funcs, fn_qn);
                slots[si] = (fn_ref != (i8*)0) ? fn_ref : LLVMConstPointerNull(ptr_t);
                si = si + 1;
            }
            let mut vtbl_init: *i8= LLVMConstNamedStruct(vtbl_ty, slots, (u32)nmeth);
            arc_free((i8*)slots);
            let mut vtbl_gname: [512]i8;
            snprintf(vtbl_gname, (u64)512, "%s__IFACE__%s__vtable", nd.name, base_name);
            let mut vtbl_gname_dup: *i8= lexer.str_dup(vtbl_gname);
            let mut vtbl_gv: *i8= LLVMAddGlobal(ctx.llvm_mod, vtbl_ty, vtbl_gname_dup);
            LLVMSetInitializer(vtbl_gv, vtbl_init);
            LLVMSetGlobalConstant(vtbl_gv, 1);
            let mut iface_key: [512]i8;
            snprintf(iface_key, (u64)512, "%s__IFACE__%s", nd.name, base_name);
            sv_map_set(&ctx.iface_concrete_vtables, lexer.str_dup(iface_key), vtbl_gv);
            bi = bi + 1;
        }
    }

    ctx.current_namespace       = saved_ns;
    ctx.current_class_name      = saved_cls;
    ctx.current_ns_is_istruc    = saved_is_istruc;
    ctx.current_ns_is_interface = saved_is_interface;
}

// ---- Extern C block ----

fn visit_extern_c_block(blk: *parser.extern_c_block, ctx: *ir_context) void {
    // Pass 1: register prototypes
    let mut i: i32= 0;
    while (i < blk.decls_len) {
        let mut decl: *parser.ast_node= blk.decls[i];
        if (decl != (parser.ast_node*)0 && decl.kind == nd_func_decl) {
            let mut fd: *parser.func_decl= (parser.func_decl*)decl;
            fd.is_extern_c = true;
            visit_func_decl_prototype(fd, ctx);
        }
        i = i + 1;
    }
    // Pass 2: emit bodies for functions that have them
    let mut j: i32= 0;
    while (j < blk.decls_len) {
        let mut decl: *parser.ast_node= blk.decls[j];
        if (decl != (parser.ast_node*)0 && decl.kind == nd_func_decl) {
            let mut fd: *parser.func_decl= (parser.func_decl*)decl;
            if (fd.has_body) {
                fd.is_extern_c = true;
                visit_func_decl(fd, ctx);
            }
        }
        j = j + 1;
    }
}

// ---- Top-level dispatch ----

fn visit_top_level_decl(node: *parser.ast_node, ctx: *ir_context) void {
    if (node == (parser.ast_node*)0) { return; }
    let mut kind: i32= node.kind;

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
        let mut vd: *parser.var_decl= (parser.var_decl*)node;
        if (vd.is_constexpr) { register_constexpr(vd, ctx); }
        if (vd.is_sta) { return; }  // compile-time only
        // const NAME = ns.func — auto/no explicit type, init is a function ref → register as func alias
        let mut vd_is_auto_t: bool= (vd.type == (parser.type_node*)0 ||
                                     (vd.type != (parser.type_node*)0 && vd.type.is_auto));
        if (vd_is_auto_t && vd.has_init && vd.init != (parser.expr_node*)0) {
            let mut fn_init: *i8= visit_expr(vd.init, ctx);
            if (fn_init != (i8*)0) {
                let mut fn_init_gvt: *i8= LLVMGlobalGetValueType(fn_init);
                if (fn_init_gvt != (i8*)0 && LLVMGetTypeKind(fn_init_gvt) == LLVMFunctionTypeKind) {
                    sv_map_set(&ctx.global_funcs,      vd.name, fn_init);
                    st_map_set(&ctx.global_func_types, vd.name, fn_init_gvt);
                    return;
                }
            }
        }
        let mut gt: *i8= llvm_type_of(vd.type, ctx);
        let mut gv: *i8= LLVMAddGlobal(ctx.llvm_mod, gt, vd.name);
        // `extern let name: T;` — the definition lives in another translation unit.
        // Leave the global without an initializer so LLVM emits a declaration; adding
        // one here would define the symbol and collide at link time.
        if (vd.is_extern) {
            sv_map_set(&ctx.global_vars, vd.name, gv);
            if (is_unsigned_type_node(vd.type)) {
                sb_map_set(&ctx.global_var_unsigned, vd.name, true);
            }
            return;
        }
        let mut init_v: *i8= (i8*)0;
        if (vd.has_init) {
            init_v = visit_expr(vd.init, ctx);
            // Coerce constant initializer to match global type (e.g. i64 literal → i32).
            // Extract the numeric value and recreate with correct type.
            if (init_v != (i8*)0 && gt != (i8*)0 && LLVMTypeOf(init_v) != gt) {
                let mut ik: i32= LLVMGetTypeKind(LLVMTypeOf(init_v));
                let mut gk: i32= LLVMGetTypeKind(gt);
                if (ik == LLVMIntegerTypeKind && gk == LLVMIntegerTypeKind) {
                    let mut raw: i64= LLVMConstIntGetSExtValue(init_v);
                    init_v = LLVMConstInt(gt, (u64)raw, 1);
                }
            }
        }
        if (init_v != (i8*)0) {
            LLVMSetInitializer(gv, init_v);
        } else {
            LLVMSetInitializer(gv, LLVMConstNull(gt));
        }
        if (!vd.is_pub) {
            LLVMSetLinkage(gv, LLVMInternalLinkage);
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

fn visit_program(prog: *parser.program_node, ctx: *ir_context) void {
    // Pre-register compiler-built types so stdlib functions can access their fields
    ensure_typeinfo_types(ctx);

    // Pre-pass: register top-level comptime constants before type/function processing
    let mut pre_tl: i32= 0;
    while (pre_tl < prog.decls_len) {
        let mut ptl: *parser.ast_node= prog.decls[pre_tl];
        if (ptl != (parser.ast_node*)0 && ptl.kind == nd_var_decl) {
            let mut pvd: *parser.var_decl= (parser.var_decl*)ptl;
            register_constexpr(pvd, ctx);
        }
        pre_tl = pre_tl + 1;
    }

    // Pass 1: register all types and function prototypes
    let mut i: i32= 0;
    while (i < prog.decls_len) {
        visit_top_level_decl(prog.decls[i], ctx);
        i = i + 1;
    }

    // Pass 2: emit function bodies
    let mut j: i32= 0;
    while (j < prog.decls_len) {
        let mut decl: *parser.ast_node= prog.decls[j];
        if (decl != (parser.ast_node*)0 && decl.kind == nd_func_decl) {
            visit_func_decl((parser.func_decl*)decl, ctx);
        }
        j = j + 1;
    }
}

} // namespace ir
