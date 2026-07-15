@include <alloc.arc>
@include <bind/llvm.arc>
@include <preproc.arc>
@include <lexer/main.arc>
@include <parser/expr.arc>
@include <parser/main.arc>
@include <diagnostics.arc>
@include <analysis/scope.arc>
@include <analysis/types.arc>
@include <analysis/main.arc>
@include <smt/main.arc>
@include <ir/context.arc>
@include <ir/types.arc>
@include <ir/names.arc>
@include <ir/exprs.arc>
@include <ir/stmts.arc>
// Declaration IR generation for the Artemis self-hosting compiler.

namespace ir {

// Forward declaration
void visit_top_level_decl(parser.ast_node* node, ir_context* ctx);

// ---- Struct declaration ----

void visit_struct_decl(parser.struct_decl* d, ir_context* ctx) {
    // Idempotency guard: if the struct is already registered, skip re-creation
    // to avoid LLVM creating a duplicate named type (e.g. "soa_layout.1").
    if (st_map_get(&ctx.struct_types, d.name) != (i8*)0) { return; }

    // Create an opaque named struct and register it
    i8* struct_t = LLVMStructCreateNamed(ctx.llvm_ctx, d.name);
    st_map_set(&ctx.struct_types, d.name, struct_t);

    // Build field type arrays
    i32 nfields = d.fields_len;
    i8** field_types_arr = (i8**)arc_malloc(sizeof(i8*) * (u64)nfields);

    struct_meta sm;
    sm.name = d.name;
    sm.is_union = d.is_union;
    sm.is_istruc = ctx.current_ns_is_istruc;
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
    arc_free((i8*)field_types_arr);

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
        sm.is_istruc = false;
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
                vsm.is_istruc = false;
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
        sv_map_set(&ctx.global_vars, lexer.str_dup(qname), gv);
        sv_map_set(&ctx.global_vars, d.variant_names[i], gv);
        // Also register with __NS_ separator so `EnumName.variant` resolves via member-access chain
        i8 ns_qname[512];
        snprintf(ns_qname, (u64)512, "%s__NS_%s", d.name, d.variant_names[i]);
        sv_map_set(&ctx.global_vars, lexer.str_dup(ns_qname), gv);
        next_val = next_val + 1;
        i = i + 1;
    }
}

// ---- Typedef declaration ----

void visit_typedef_decl(parser.typedef_decl* d, ir_context* ctx) {
    // `using ns_name;` — namespace import
    if (d.is_namespace_using) {
        if (d.ns_using_name != (i8*)0) { ctx_add_using_ns(ctx, d.ns_using_name); }
        return;
    }
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

// Returns true if fd is an istruc method that needs an implicit self pointer prepended.
// Conditions: in istruc namespace, not static, and first param is NOT a ptr-to-struct.
bool func_needs_implicit_self(parser.func_decl* fd, ir_context* ctx) {
    if (!ctx.current_ns_is_istruc) { return false; }
    if (fd.is_static) { return false; }
    // If no params at all → implicit self
    if (fd.params_len == 0 || fd.params == (parser.param_decl*)0) { return true; }
    // Check if first param is a pointer to the struct type (explicit self)
    parser.type_node* fp = fd.params[0].type;
    if (fp == (parser.type_node*)0) { return true; }
    if (fp.pointer_depth <= 0 || fp.is_primitive) { return true; }
    if (fp.name == (i8*)0 || ctx.current_class_name == (i8*)0) { return true; }
    // Exact match (non-generic) → explicit self
    if (strcmp(fp.name, ctx.current_class_name) == 0) { return false; }
    // Monomorphized case: current_class_name starts with fp.name + "__G_"
    // e.g. fp.name="Pair", current_class_name="Pair__G_i32"
    i32 base_len = (i32)strlen(fp.name);
    if (strncmp(ctx.current_class_name, fp.name, (u64)base_len) == 0) {
        i8* suffix = ctx.current_class_name + base_len;
        if (suffix[0] == '_' && suffix[1] == '_' && suffix[2] == 'G' && suffix[3] == '_') {
            return false; // explicit self (generic monomorphized)
        }
    }
    return true;
}

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

    // Detect implicit self: istruc method whose first param is NOT a ptr-to-struct
    bool implicit_self = func_needs_implicit_self(fd, ctx);
    i32 self_offset = implicit_self ? 1 : 0;

    // Build parameter types (with optional implicit self ptr prepended)
    i32 nparams = fd.params_len + self_offset;
    i8** param_types = (i8**)0;
    if (nparams > 0) {
        param_types = (i8**)arc_malloc(sizeof(i8*) * (u64)nparams);
        if (implicit_self) {
            param_types[0] = LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
        }
        i32 i = 0;
        while (i < fd.params_len) {
            i8* pt = llvm_type_of(fd.params[i].type, ctx);
            if (pt == (i8*)0) { pt = LLVMVoidTypeInContext(ctx.llvm_ctx); }
            param_types[i + self_offset] = pt;
            i = i + 1;
        }
    }
    i32 variadic = fd.is_variadic ? 1 : 0;
    i8* fn_type  = LLVMFunctionType(ret_t, param_types, nparams, variadic);
    if (param_types != (i8**)0) { arc_free((i8*)param_types); }

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

    // Detect implicit self (same logic as prototype)
    bool impl_self = func_needs_implicit_self(fd, ctx);
    i32 self_offset = impl_self ? 1 : 0;

    // Bind implicit self pointer (param 0) as `self` in scope
    if (impl_self) {
        i8* self_val = LLVMGetParam(fn, 0);
        i8* ptr_t    = LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
        i8* self_alloca = LLVMBuildAlloca(ctx.llvm_builder, ptr_t, "self");
        LLVMBuildStore(ctx.llvm_builder, self_val, self_alloca);
        // Determine deref type from struct name
        i8* deref_t = (ctx.current_class_name != (i8*)0) ? st_map_get(&ctx.struct_types, ctx.current_class_name) : (i8*)0;
        ctx_declare_local(ctx, "self", self_alloca, ptr_t, deref_t, false);
    }

    // Alloca for each parameter
    i32 i = 0;
    while (i < fd.params_len) {
        parser.param_decl p = fd.params[i];
        i8* param_val = LLVMGetParam(fn, i + self_offset);
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
            // Non-void function fell off end — compile error
            i8* fname = fd.name != (i8*)0 ? fd.name : "<anonymous>";
            printf("error: function '%s' may not return on all paths (line %d)\n", fname, (i32)fd.line);
            ctx.had_error = true;
            LLVMBuildRet(ctx.llvm_builder, LLVMConstNull(rv));
        }
    }

    ctx_pop_scope(ctx);
    ctx.current_func      = (i8*)0;
    ctx.current_func_type = (i8*)0;
    ctx.current_ret_type  = (i8*)0;
}

// ---- Generic class monomorphization ----

i8* ir_get_or_monomorphize_generic_class(parser.type_node* t, ir_context* ctx) {
    if (t == (parser.type_node*)0 || t.type_args_len == 0 || t.name == (i8*)0) {
        return (i8*)0;
    }
    i8* base_name = t.name;

    // Build mono_name: base__G_<arg1>_<arg2>...
    i8 mono_name[512];
    i32 mn_off = snprintf(mono_name, (u64)512, "%s__G", base_name);
    i32 tai = 0;
    while (tai < t.type_args_len) {
        parser.type_node* ta = (parser.type_node*)t.type_args[tai];
        i8* ta_m = mangle_type(ta);
        i32 tl = (i32)strlen(ta_m);
        if (mn_off + tl + 2 < 510) {
            mono_name[mn_off] = '_';
            mn_off = mn_off + 1;
            i32 ci = 0;
            while (ci < tl) { mono_name[mn_off + ci] = ta_m[ci]; ci = ci + 1; }
            mn_off = mn_off + tl;
            mono_name[mn_off] = 0;
        }
        tai = tai + 1;
    }
    i8* mono_name_dup = lexer.str_dup(mono_name);

    // Already instantiated?
    i8* existing = st_map_get(&ctx.struct_types, mono_name_dup);
    if (existing != (i8*)0) { return existing; }

    // Look up generic class registry
    i8* gnd_ptr = sv_map_get(&ctx.generic_classes, base_name);
    if (gnd_ptr == (i8*)0) { return (i8*)0; }
    parser.namespace_decl* gnd = (parser.namespace_decl*)gnd_ptr;

    // Find struct_decl or enum_decl child
    parser.struct_decl* sd = (parser.struct_decl*)0;
    parser.enum_decl* ged = (parser.enum_decl*)0;
    i32 di = 0;
    while (di < gnd.decls_len) {
        parser.ast_node* gnd_di = gnd.decls[di];
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
        i8* saved_ged_name = ged.name;
        ged.name = mono_name_dup;
        visit_enum_decl(ged, ctx);
        ged.name = saved_ged_name;
        // Register mono name as struct type alias for type resolution (enums resolve to i32)
        i8* i32t2 = LLVMInt32TypeInContext(ctx.llvm_ctx);
        st_map_set(&ctx.struct_types, mono_name_dup, i32t2);
        return i32t2;
    }

    // Bind type params and class name itself (so `vector*` self resolves to mono_struct*)
    // We bind before creating the struct so circular refs use a placeholder.
    // Class name is bound AFTER the struct is created (see below).
    i32 tpi = 0;
    while (tpi < gnd.type_params_len && tpi < t.type_args_len) {
        parser.type_node* ta = (parser.type_node*)t.type_args[tpi];
        i8* ta_llvm = llvm_type_of(ta, ctx);
        st_map_set(&ctx.type_param_bindings, gnd.type_params[tpi], ta_llvm);
        tpi = tpi + 1;
    }

    // Create named LLVM struct (register early to handle recursive refs)
    i8* mono_struct = LLVMStructCreateNamed(ctx.llvm_ctx, mono_name_dup);
    st_map_set(&ctx.struct_types, mono_name_dup, mono_struct);
    // Bind class short name so `vector*` self params resolve to mono_struct*
    st_map_set(&ctx.type_param_bindings, gnd.name, mono_struct);

    // Build field types and struct_meta
    struct_meta sm;
    sm.name = mono_name_dup;
    sm.is_union = gnd.is_union;
    sm.is_istruc = gnd.is_istruc;
    name_list_init(&sm.field_names);
    type_list_init(&sm.field_types);
    bool_list_init(&sm.field_unsigned);
    type_list_init(&sm.field_pointee);

    if (sd != (parser.struct_decl*)0 && sd.fields_len > 0) {
        i32 nfields = sd.fields_len;
        i8** fts = (i8**)arc_malloc(sizeof(i8*) * (u64)nfields);
        i32 fi = 0;
        while (fi < nfields) {
            parser.var_decl* f = sd.fields[fi];
            i8* ft = llvm_type_of(f.type, ctx);
            fts[fi] = ft;
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
            fi = fi + 1;
        }
        if (gnd.is_union) {
            u64 max_size = 0;
            i32 ui = 0;
            while (ui < nfields) {
                u64 fsz = llvm_type_byte_size(fts[ui]);
                if (fsz > max_size) { max_size = fsz; }
                ui = ui + 1;
            }
            if (max_size == 0) { max_size = 1; }
            i8* i8t = LLVMInt8TypeInContext(ctx.llvm_ctx);
            i8* arr_t = LLVMArrayType(i8t, (u32)max_size);
            i8* union_body[1];
            union_body[0] = arr_t;
            LLVMStructSetBody(mono_struct, union_body, 1, 0);
        } else {
            LLVMStructSetBody(mono_struct, fts, nfields, 0);
        }
        arc_free((i8*)fts);
    } else {
        i8** empty = (i8**)arc_malloc(sizeof(i8*));
        LLVMStructSetBody(mono_struct, empty, 0, 0);
        arc_free((i8*)empty);
    }
    struct_meta_vec_push(&ctx.struct_meta_tbl, sm);

    // Save builder position — monomorphization may be triggered mid-function.
    i8* saved_insert_bb = LLVMGetInsertBlock(ctx.llvm_builder);

    // Emit methods in a namespace named after the monomorphized type
    i8* saved_ns = ctx.current_namespace;
    ctx.current_namespace = mono_name_dup;
    i8* saved_cls = ctx.current_class_name;
    ctx.current_class_name = mono_name_dup;

    // Pre-pass: assign qualified names to every func_decl in gnd.decls.
    // Overloading is not supported � duplicate function names emit an error.
    // Forward declarations (no body) always get the base name and don't count as duplicates.
    i8** ol_qnames = (i8**)arc_malloc(sizeof(i8*) * (u64)(gnd.decls_len + 1));
    i8*  seen_names[64];
    i32  seen_len = 0;
    i32 pre = 0;
    while (pre < gnd.decls_len) {
        parser.ast_node* pd = gnd.decls[pre];
        if (pd != (parser.ast_node*)0 && pd.kind == nd_func_decl) {
            parser.func_decl* pfd = (parser.func_decl*)pd;
            i8 base[512];
            snprintf(base, (u64)512, "%s__NS_%s", mono_name_dup, pfd.name);
            ol_qnames[pre] = lexer.str_dup(base);
            if (pfd.has_body) {
                bool already_seen = false;
                i32 si = 0;
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
    i32 mi = 0;
    while (mi < gnd.decls_len) {
        parser.ast_node* decl = gnd.decls[mi];
        if (decl != (parser.ast_node*)0 && decl.kind == nd_func_decl) {
            parser.func_decl* fd = (parser.func_decl*)decl;
            i8* qn = ol_qnames[mi];
            if (qn != (i8*)0) {
                i8* on = fd.name; i8* om = fd.mangled_name; i32 otl = fd.type_params_len;
                fd.name = qn; fd.mangled_name = (i8*)0; fd.type_params_len = 0;
                visit_func_decl_prototype(fd, ctx);
                fd.name = on; fd.mangled_name = om; fd.type_params_len = otl;
            }
        }
        mi = mi + 1;
    }

    // Pass 2: bodies
    i32 mj = 0;
    while (mj < gnd.decls_len) {
        parser.ast_node* decl = gnd.decls[mj];
        if (decl != (parser.ast_node*)0 && decl.kind == nd_func_decl) {
            parser.func_decl* fd = (parser.func_decl*)decl;
            i8* qn = ol_qnames[mj];
            if (qn != (i8*)0) {
                i8* on = fd.name; i8* om = fd.mangled_name; i32 otl = fd.type_params_len;
                i8* sf = ctx.current_func; i8* sft = ctx.current_func_type;
                i8* srt = ctx.current_ret_type;
                bool seu = ctx.current_func_is_error_union;
                i8* seut = ctx.current_error_union_type;
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

    // Clear type param bindings (including class short name)
    tpi = 0;
    while (tpi < gnd.type_params_len) {
        st_map_set(&ctx.type_param_bindings, gnd.type_params[tpi], (i8*)0);
        tpi = tpi + 1;
    }
    st_map_set(&ctx.type_param_bindings, gnd.name, (i8*)0);

    ctx.current_namespace = saved_ns;
    ctx.current_class_name = saved_cls;

    // Restore builder position in case we were mid-function when triggered.
    if (saved_insert_bb != (i8*)0) {
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, saved_insert_bb);
    }
    return mono_struct;
}

// ---- memstr fat-pointer support ----

// Ensure __memstr_fat__ and vtable struct types are created in the context.
void ensure_memstr_types(ir_context* ctx) {
    if (ctx.memstr_fat_type != (i8*)0) { return; }
    // vtable struct: { ptr mmap_fn, ptr rmap_fn, ptr deinit_fn }
    i8* vfields[3];
    i8* ptr_t = LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
    vfields[0] = ptr_t; vfields[1] = ptr_t; vfields[2] = ptr_t;
    ctx.memstr_vtable_type = LLVMStructTypeInContext(ctx.llvm_ctx, vfields, 3, 0);
    // fat pointer struct: { ptr data, ptr vtable }
    i8* ffields[2];
    ffields[0] = ptr_t; ffields[1] = ptr_t;
    ctx.memstr_fat_type = LLVMStructCreateNamed(ctx.llvm_ctx, "__memstr_fat__");
    LLVMStructSetBody(ctx.memstr_fat_type, ffields, 2, 0);
    st_map_set(&ctx.struct_types, lexer.str_dup("__memstr_fat__"), ctx.memstr_fat_type);
}

// Emit a vtable global for a memstr class. The vtable is:
//   @ClassName__vtable__ = constant { ptr, ptr, ptr } { ptr @mmap, ptr @rmap, ptr @deinit }
// Methods are looked up by qualified name ClassName__NS_<method>.
void emit_memstr_vtable(parser.namespace_decl* nd, i8* qual_name, ir_context* ctx) {
    ensure_memstr_types(ctx);
    i8 vtname[512];
    snprintf(vtname, (u64)512, "%s__vtable__", nd.name);
    // Build vtable constant: { ptr mmap, ptr rmap, ptr deinit }
    i8* slots[3];
    i8* mnames[3];
    // Methods are registered under nd.name__NS_method (short form), not qual_name__NS_method.
    i8 buf0[512]; snprintf(buf0, (u64)512, "%s__NS_mmap",   nd.name); mnames[0] = buf0;
    i8 buf1[512]; snprintf(buf1, (u64)512, "%s__NS_rmap",   nd.name); mnames[1] = buf1;
    i8 buf2[512]; snprintf(buf2, (u64)512, "%s__NS_deinit", nd.name); mnames[2] = buf2;
    i8* ptr_t = LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
    i32 si = 0;
    while (si < 3) {
        i8* fn = LLVMGetNamedFunction(ctx.llvm_mod, mnames[si]);
        if (fn != (i8*)0) { slots[si] = fn; }
        else               { slots[si] = LLVMConstPointerNull(ptr_t); }
        si = si + 1;
    }
    i8* vtinit = LLVMConstStructInContext(ctx.llvm_ctx, slots, 3, 0);
    i8* vtglobal = LLVMAddGlobal(ctx.llvm_mod, ctx.memstr_vtable_type, vtname);
    LLVMSetInitializer(vtglobal, vtinit);
    LLVMSetGlobalConstant(vtglobal, 1);
    sv_map_set(&ctx.memstr_vtables, lexer.str_dup(nd.name), vtglobal);
    sv_map_set(&ctx.memstr_vtables, lexer.str_dup(qual_name), vtglobal);
}

// ---- Comptime constant expression evaluator ----

// Evaluate a compile-time constant expression to an i64.
// Returns true on success (stores result in *out), false if not evaluable.
bool constexpr_eval_expr(parser.expr_node* e, ir_context* ctx, i64* out) {
    if (e == (parser.expr_node*)0) { return false; }
    i32 k = e.kind;
    if (k == ek_int_lit) { *out = e.int_val; return true; }
    if (k == ek_bool_lit) { *out = e.bool_val ? (i64)1 : (i64)0; return true; }
    if (k == ek_identifier && e.str_val != (i8*)0) {
        i8* cv = sv_map_get(&ctx.constexpr_int_vals_map, e.str_val);
        if (cv != (i8*)0) { *out = (i64)cv; return true; }
        if (ctx.current_namespace != (i8*)0) {
            i8 fqn[512];
            snprintf(fqn, (u64)512, "%s__NS_%s", ctx.current_namespace, e.str_val);
            cv = sv_map_get(&ctx.constexpr_int_vals_map, fqn);
            if (cv != (i8*)0) { *out = (i64)cv; return true; }
        }
        return false;
    }
    if (k == ek_binary) {
        i64 lv = 0; i64 rv2 = 0;
        if (!constexpr_eval_expr(e.lhs, ctx, &lv)) { return false; }
        if (!constexpr_eval_expr(e.rhs, ctx, &rv2)) { return false; }
        i32 op = e.bop;
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
        i64 v = 0;
        if (!constexpr_eval_expr(e.operand, ctx, &v)) { return false; }
        if (e.uop == uop_neg) { *out = -v; return true; }
        if (e.uop == uop_bit_not) { *out = ~v; return true; }
        if (e.uop == uop_log_not) { *out = (v == (i64)0) ? (i64)1 : (i64)0; return true; }
        return false;
    }
    if (k == ek_cast) { return constexpr_eval_expr(e.operand, ctx, out); }
    return false;
}

// Register a comptime variable's value in constexpr_int_vals_map under several names.
void register_constexpr(parser.var_decl* pvd, ir_context* ctx) {
    if (pvd == (parser.var_decl*)0 || !pvd.is_constexpr) { return; }
    if (!pvd.has_init || pvd.init == (parser.expr_node*)0) { return; }
    if (pvd.name == (i8*)0) { return; }
    i64 iv = 0;
    if (!constexpr_eval_expr(pvd.init, ctx, &iv)) { return; }
    sv_map_set(&ctx.constexpr_int_vals_map, lexer.str_dup(pvd.name), (i8*)iv);
    if (ctx.current_namespace != (i8*)0) {
        i8 qn[512];
        snprintf(qn, (u64)512, "%s__NS_%s", ctx.current_namespace, pvd.name);
        sv_map_set(&ctx.constexpr_int_vals_map, lexer.str_dup(qn), (i8*)iv);
    }
}

// ---- Namespace ----

void visit_namespace_decl(parser.namespace_decl* nd, ir_context* ctx) {
    i8* saved_ns        = ctx.current_namespace;
    i8* saved_cls       = ctx.current_class_name;
    bool saved_is_istruc = ctx.current_ns_is_istruc;
    i8 ns_buf[256];
    if (saved_ns != (i8*)0) {
        snprintf(ns_buf, (u64)256, "%s__NS_%s", saved_ns, nd.name);
i32 main(i32 argc, i8** argv) { return 0; }
