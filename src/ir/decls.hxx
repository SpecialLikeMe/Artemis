#pragma once
#include "stmts.hxx"
#include "names.hxx"

// Forward declare the top-level dispatcher.
inline void visit_top_level_decl(ast_node* node, ir_context* ctx);
inline void visit_func_decl_prototype(func_decl* fd, ir_context* ctx);

// ------------------------------------------------------------------ struct

inline void visit_struct_decl(struct_decl* d, ir_context* ctx) {
    // Create an opaque named struct type and register it BEFORE computing field types
    // so that self-referential pointer fields (e.g. ifo_t.elem_type: ifo_t*) resolve
    // correctly instead of falling back to i8*.
    LLVMTypeRef struct_t = LLVMStructCreateNamed(ctx->llvm_ctx, d->name.c_str());
    ctx->struct_types[d->name] = struct_t;

    std::vector<LLVMTypeRef> field_types;
    std::vector<std::string> field_names;
    std::vector<bool>        field_unsigned;
    std::vector<LLVMTypeRef> field_pointee; // pointee LLVM type for pointer fields (nullptr otherwise)

    for (auto* f : d->fields) {
        field_types.push_back(llvm_type_of(f->type, ctx));
        field_names.push_back(f->name);
        field_unsigned.push_back(is_unsigned_type_node(f->type));
        if (f->type && f->type->pointer_depth > 0) {
            type_node stripped = *f->type;
            stripped.pointer_depth--;
            stripped.array_size = std::nullopt;
            field_pointee.push_back(llvm_type_of(&stripped, ctx));
        } else {
            field_pointee.push_back(nullptr);
        }
    }

    LLVMStructSetBody(struct_t,
                      field_types.data(),
                      static_cast<unsigned>(field_types.size()),
                      /*packed=*/0);

    ctx->struct_field_names[d->name]         = std::move(field_names);
    ctx->struct_field_types[d->name]         = std::move(field_types);
    ctx->struct_field_unsigned[d->name]      = std::move(field_unsigned);
    ctx->struct_field_pointee_types[d->name] = std::move(field_pointee);
}

// ------------------------------------------------------------------ union

inline void visit_union_decl(union_decl* d, ir_context* ctx) {
    // LLVM has no native union type. Represent as a byte array sized to the largest field.
    // The real implementation would use a packed struct with the widest member + padding.
    // For now we register it as an opaque struct and let the user refine.
    LLVMTypeRef union_t = LLVMStructCreateNamed(ctx->llvm_ctx, d->name.c_str());

    std::vector<std::string> field_names;
    LLVMTypeRef widest_t = LLVMInt8TypeInContext(ctx->llvm_ctx);
    unsigned    widest_w = 0;

    for (auto* f : d->fields) {
        field_names.push_back(f->name);
        LLVMTypeRef ft = llvm_type_of(f->type, ctx);
        unsigned    fw = LLVMGetIntTypeWidth(ft); // approximation; use data layout for real size
        if (fw > widest_w) { widest_w = fw; widest_t = ft; }
    }

    LLVMStructSetBody(union_t, &widest_t, 1, /*packed=*/0);

    std::vector<LLVMTypeRef> field_types_vec;
    for (auto* f : d->fields) field_types_vec.push_back(llvm_type_of(f->type, ctx));

    std::vector<bool> field_unsigned_vec;
    for (auto* f : d->fields) field_unsigned_vec.push_back(is_unsigned_type_node(f->type));

    ctx->struct_types[d->name]          = union_t;
    ctx->struct_field_names[d->name]    = std::move(field_names);
    ctx->struct_field_types[d->name]    = std::move(field_types_vec);
    ctx->struct_field_unsigned[d->name] = std::move(field_unsigned_vec);
    ctx->union_names.insert(d->name);
}

// ------------------------------------------------------------------ enum

inline void visit_enum_decl(enum_decl* d, ir_context* ctx) {
    LLVMTypeRef i32t = LLVMInt32TypeInContext(ctx->llvm_ctx);
    LLVMTypeRef i8t  = LLVMInt8TypeInContext(ctx->llvm_ctx);

    if (!d->is_adt) {
        // Simple C-style enum: variants become i32 global constants.
        int next_val = 0;
        for (auto* ev : d->variants) {
            if (ev->plain_val.has_value()) {
                LLVMValueRef cv = visit_expr(ev->plain_val.value(), ctx);
                if (LLVMIsConstant(cv))
                    next_val = static_cast<int>(LLVMConstIntGetSExtValue(cv));
            }
            std::string qname = d->name + "::" + ev->name;
            LLVMValueRef global = LLVMAddGlobal(ctx->llvm_mod, i32t, qname.c_str());
            LLVMSetInitializer(global, LLVMConstInt(i32t, next_val, 1));
            LLVMSetGlobalConstant(global, 1);
            LLVMSetLinkage(global, LLVMInternalLinkage);
            ctx->global_vars[ev->name] = global;
            ctx->global_vars[qname]    = global;
            next_val++;
        }
        return;
    }

    // ADT enum: { i32 tag, [N x i8] payload } (packed)
    unsigned max_payload = 0;
    int tag_idx = 0;
    for (auto* ev : d->variants) {
        std::string qname = d->name + "::" + ev->name;
        LLVMValueRef tg = LLVMAddGlobal(ctx->llvm_mod, i32t, (qname + "__tag").c_str());
        LLVMSetInitializer(tg, LLVMConstInt(i32t, tag_idx, 0));
        LLVMSetGlobalConstant(tg, 1);
        LLVMSetLinkage(tg, LLVMInternalLinkage);
        ctx->global_vars[ev->name + "__tag"] = tg;
        ctx->global_vars[qname + "__tag"]    = tg;

        unsigned payload = 0;
        switch (ev->kind) {
        case enum_variant_kind::plain: payload = 0; break;
        case enum_variant_kind::tuple:
            for (auto* tt : ev->tuple_types)
                payload += adt_type_byte_size(llvm_type_of(tt, ctx), ctx);
            break;
        case enum_variant_kind::named_struct:
            for (auto* f : ev->struct_fields)
                payload += adt_type_byte_size(llvm_type_of(f->type, ctx), ctx);
            break;
        case enum_variant_kind::istruc_body:
            if (ev->istruc_body)
                for (auto* cf : ev->istruc_body->fields)
                    payload += adt_type_byte_size(llvm_type_of(cf->type, ctx), ctx);
            break;
        }
        if (payload > max_payload) max_payload = payload;
        tag_idx++;
    }

    // Build LLVM struct type { i32, [max_payload x i8] }
    LLVMTypeRef adt_t = LLVMStructCreateNamed(ctx->llvm_ctx, d->name.c_str());
    std::vector<LLVMTypeRef> body;
    body.push_back(i32t);
    if (max_payload > 0) body.push_back(LLVMArrayType(i8t, max_payload));
    LLVMStructSetBody(adt_t, body.data(), (unsigned)body.size(), /*packed=*/1);
    ctx->struct_types[d->name] = adt_t;

    ctx->struct_field_names[d->name] = {"__tag", "__payload"};
    std::vector<LLVMTypeRef> ftv = {i32t};
    if (max_payload > 0) ftv.push_back(LLVMArrayType(i8t, max_payload));
    ctx->struct_field_types[d->name] = std::move(ftv);

    // Register in adt_enums for expression-level payload access
    ctx->adt_enums[d->name] = d;

    // Emit constructor functions for non-plain variants
    tag_idx = 0;
    for (auto* ev : d->variants) {
        if (ev->kind == enum_variant_kind::plain) { tag_idx++; continue; }

        std::vector<LLVMTypeRef> params;
        std::vector<std::string> pnames;
        switch (ev->kind) {
        case enum_variant_kind::tuple:
            for (size_t i = 0; i < ev->tuple_types.size(); i++) {
                params.push_back(llvm_type_of(ev->tuple_types[i], ctx));
                pnames.push_back("_t" + std::to_string(i));
            }
            break;
        case enum_variant_kind::named_struct:
            for (auto* f : ev->struct_fields) {
                params.push_back(llvm_type_of(f->type, ctx));
                pnames.push_back(f->name);
            }
            break;
        case enum_variant_kind::istruc_body:
            if (ev->istruc_body) {
                // Check if a user-defined __construct__ exists; if so, skip the auto-gen
                // field-copy ctor here — a proper wrapper is emitted after pass 1b.
                bool has_user_ctor = false;
                for (auto* m : ev->istruc_body->methods)
                    if (m->name == "__construct__") { has_user_ctor = true; break; }
                if (!has_user_ctor) {
                    for (auto* cf : ev->istruc_body->fields) {
                        params.push_back(llvm_type_of(cf->type, ctx));
                        pnames.push_back(cf->name);
                    }
                }
            }
            break;
        default: break;
        }

        // Skip ctor emission entirely for istruc_body variants with a user __construct__.
        // The wrapper ctor is generated after method prototypes are registered (pass 1b.5).
        if (ev->kind == enum_variant_kind::istruc_body && ev->istruc_body) {
            bool has_user_ctor = false;
            for (auto* m : ev->istruc_body->methods)
                if (m->name == "__construct__") { has_user_ctor = true; break; }
            if (has_user_ctor) { tag_idx++; continue; }
        }

        std::string ctor = d->name + "__" + ev->name + "__ctor";
        LLVMTypeRef fn_t = LLVMFunctionType(adt_t,
            params.empty() ? nullptr : params.data(),
            (unsigned)params.size(), 0);
        LLVMValueRef fn = LLVMAddFunction(ctx->llvm_mod, ctor.c_str(), fn_t);
        LLVMBasicBlockRef bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "entry");
        LLVMPositionBuilderAtEnd(ctx->llvm_builder, bb);

        LLVMValueRef alloca = LLVMBuildAlloca(ctx->llvm_builder, adt_t, "adt");
        LLVMValueRef tag_ptr = LLVMBuildStructGEP2(ctx->llvm_builder, adt_t, alloca, 0, "tagp");
        LLVMBuildStore(ctx->llvm_builder, LLVMConstInt(i32t, tag_idx, 0), tag_ptr);

        if (!params.empty() && max_payload > 0) {
            LLVMValueRef payload_ptr = LLVMBuildStructGEP2(ctx->llvm_builder, adt_t, alloca, 1, "payp");
            unsigned byte_off = 0;
            for (size_t i = 0; i < params.size(); i++) {
                LLVMValueRef pv = LLVMGetParam(fn, (unsigned)i);
                LLVMValueRef of = LLVMConstInt(LLVMInt64TypeInContext(ctx->llvm_ctx), byte_off, 0);
                LLVMValueRef fp = LLVMBuildGEP2(ctx->llvm_builder, i8t, payload_ptr, &of, 1, "fp");
                LLVMValueRef fc = LLVMBuildBitCast(ctx->llvm_builder, fp,
                    LLVMPointerType(params[i], 0), "fc");
                LLVMBuildStore(ctx->llvm_builder, pv, fc);
                byte_off += adt_type_byte_size(params[i], ctx);
            }
        }

        LLVMValueRef ret_v = LLVMBuildLoad2(ctx->llvm_builder, adt_t, alloca, "adtv");
        LLVMBuildRet(ctx->llvm_builder, ret_v);
        ctx->global_funcs[ctor]      = fn;
        ctx->global_func_types[ctor] = fn_t;
        tag_idx++;
    }
}

// ------------------------------------------------------------------ typedef

inline void visit_typedef_decl(typedef_decl* d, ir_context* ctx) {
    // Typedefs are purely a semantic concept; record the aliased LLVM type
    // under the alias name so llvm_type_of can resolve it via struct_types.
    LLVMTypeRef underlying = llvm_type_of(d->underlying, ctx);
    // If it's a struct type with a name, just re-register under the alias.
    // Otherwise create an alias entry via a named struct wrapping it.
    if (LLVMGetTypeKind(underlying) == LLVMStructTypeKind) {
        ctx->struct_types[d->alias] = underlying;
        auto it = ctx->struct_field_names.find(LLVMGetStructName(underlying) ? LLVMGetStructName(underlying) : "");
        if (it != ctx->struct_field_names.end())
            ctx->struct_field_names[d->alias] = it->second;
    } else {
        // Scalar/pointer typedef (e.g. typedef f64 Real; typedef i32* IntPtr).
        // Record the underlying AST type so llvm_type_of resolves the alias instead
        // of defaulting unknown named types to i32.
        ctx->typedef_aliases[d->alias] = d->underlying;
    }
}

// ------------------------------------------------------------------ global variable

inline void visit_global_var_decl(var_decl* d, ir_context* ctx) {
    // sta-typed globals are comptime namespaces; no LLVM global emitted.
    if (d->is_sta || (d->type && d->type->is_sta)) return;

    LLVMTypeRef  t      = llvm_type_of(d->type, ctx);
    LLVMValueRef global = LLVMAddGlobal(ctx->llvm_mod, t, d->name.c_str());

    if (d->init.has_value()) {
        LLVMValueRef init_val = visit_expr(d->init.value(), ctx);
        if (!LLVMIsConstant(init_val))
            throw std::runtime_error("IR: Global variable '" + d->name + "' initializer must be a constant");
        LLVMSetInitializer(global, init_val);
    } else {
        LLVMSetInitializer(global, LLVMConstNull(t)); // zero-initialise
    }

    ctx->global_vars[d->name] = global;
    if (is_unsigned_type_node(d->type)) ctx->global_var_unsigned.insert(d->name);
}

// ------------------------------------------------------------------ function (pass 1: declare signature)

inline void visit_func_decl_prototype(func_decl* fd, ir_context* ctx) {
    // Set namespace context so llvm_type_of can resolve intra-namespace types.
    // Use rfind so multi-level namespaces (std__NS_ifo__NS_fn) resolve to "std__NS_ifo", not just "std".
    const std::string ir_name_pre = ir_func_name(fd);
    std::string saved_proto_ns = ctx->current_namespace;
    auto proto_ns_pos = ir_name_pre.rfind("__NS_");
    if (proto_ns_pos != std::string::npos) ctx->current_namespace = ir_name_pre.substr(0, proto_ns_pos);
    else ctx->current_namespace.clear();

    std::vector<LLVMTypeRef> param_types;
    for (auto& p : fd->params)
        param_types.push_back(llvm_type_of(p.type, ctx));

    LLVMTypeRef ret_t  = llvm_type_of(fd->ret_type, ctx);
    if (fd->is_error_union) {
        LLVMTypeRef i32t = LLVMInt32TypeInContext(ctx->llvm_ctx);
        LLVMTypeRef i8pt = LLVMPointerType(LLVMInt8TypeInContext(ctx->llvm_ctx), 0);
        if (LLVMGetTypeKind(ret_t) == LLVMVoidTypeKind) {
            // !void -> {i32 tag, i8* payload}
            LLVMTypeRef fields[2] = {i32t, i8pt};
            ret_t = LLVMStructTypeInContext(ctx->llvm_ctx, fields, 2, 0);
        } else {
            // !T -> {i32 tag, i8* payload, T ok_value}
            LLVMTypeRef fields[3] = {i32t, i8pt, ret_t};
            ret_t = LLVMStructTypeInContext(ctx->llvm_ctx, fields, 3, 0);
        }
    }
    ctx->current_namespace = saved_proto_ns;
    LLVMTypeRef fn_t   = LLVMFunctionType(ret_t,
                                           param_types.data(),
                                           static_cast<unsigned>(param_types.size()),
                                           fd->is_variadic ? 1 : 0);

    const std::string ir_name = ir_func_name(fd);

    // Reuse an existing declaration if already registered.
    LLVMValueRef fn = LLVMGetNamedFunction(ctx->llvm_mod, ir_name.c_str());
    if (!fn) fn = LLVMAddFunction(ctx->llvm_mod, ir_name.c_str(), fn_t);

    if (fd->is_noexcept) {
        unsigned k = LLVMGetEnumAttributeKindForName("nounwind", 8);
        if (k) LLVMAddAttributeAtIndex(fn, LLVMAttributeFunctionIndex,
                   LLVMCreateEnumAttribute(ctx->llvm_ctx, k, 0));
    }

    ctx->global_funcs[ir_name]      = fn;
    ctx->global_func_types[ir_name] = fn_t;
    bool ret_unsigned = is_unsigned_type_node(fd->ret_type);
    ctx->global_func_ret_unsigned[ir_name]  = ret_unsigned;
    // Also index by original name for single-overload functions
    if (ir_name != fd->name) {
        ctx->global_funcs[fd->name]             = fn;
        ctx->global_func_types[fd->name]        = fn_t;
        ctx->global_func_ret_unsigned[fd->name] = ret_unsigned;
    }
}

// ------------------------------------------------------------------ function (pass 2: emit body)

inline void visit_func_decl(func_decl* fd, ir_context* ctx) {
    const std::string ir_name = ir_func_name(fd);
    // Prototype is already registered; grab it.
    LLVMValueRef fn   = ctx->global_funcs[ir_name];
    LLVMTypeRef  fn_t = ctx->global_func_types[ir_name];

    if (!fd->body) return; // forward declaration — nothing to emit

    // DEBUG: print body stmt count for visit_except_handler
    if (fd->name == "visit_except_handler") {
        fprintf(stderr, "DEBUG visit_except_handler body->stmts.size() = %zu\n", fd->body->stmts.size());
    }

    ctx->current_func      = fn;
    ctx->current_func_type = fn_t;
    ctx->current_ret_type  = LLVMGetReturnType(fn_t);
    ctx->current_func_is_error_union = fd->is_error_union;
    ctx->current_error_union_type    = fd->is_error_union ? ctx->current_ret_type : nullptr;

    // Derive namespace context from mangled name; rfind gives the deepest parent namespace.
    // "std__NS_ifo__NS_fn" -> "std__NS_ifo" so intra-namespace types resolve correctly.
    std::string saved_ns = ctx->current_namespace;
    auto ns_pos = ir_name.rfind("__NS_");
    if (ns_pos != std::string::npos) ctx->current_namespace = ir_name.substr(0, ns_pos);
    else ctx->current_namespace.clear();

    LLVMBasicBlockRef entry_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "entry");
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, entry_bb);

    ctx->push_scope();

    // Allocate stack slots for each parameter and store the incoming value.
    for (unsigned i = 0; i < static_cast<unsigned>(fd->params.size()); i++) {
        const auto&  p        = fd->params[i];
        LLVMTypeRef  pt       = llvm_type_of(p.type, ctx);
        LLVMValueRef alloca   = LLVMBuildAlloca(ctx->llvm_builder, pt, p.name.c_str());
        LLVMValueRef arg_val  = LLVMGetParam(fn, i);
        LLVMBuildStore(ctx->llvm_builder, arg_val, alloca);
        // Track pointed-to type for pointer parameters so *param can load correctly.
        // Check is_func_ptr first: parser sets pointer_depth=1 on func-ptr types, but
        // llvm_type_of always wraps them in a pointer regardless of pointer_depth, so
        // the stripped type would give another pointer rather than the raw function type.
        LLVMTypeRef deref_t = nullptr;
        if (p.type->is_func_ptr && p.type->fp_ret) {
            LLVMTypeRef ret_t = llvm_type_of(p.type->fp_ret, ctx);
            std::vector<LLVMTypeRef> param_ts;
            for (auto* fpt : p.type->fp_params) param_ts.push_back(llvm_type_of(fpt, ctx));
            deref_t = LLVMFunctionType(ret_t, param_ts.data(),
                                       static_cast<unsigned>(param_ts.size()),
                                       p.type->fp_variadic ? 1 : 0);
        } else if (p.type->pointer_depth > 0) {
            type_node stripped = *p.type;
            stripped.pointer_depth--;
            deref_t = llvm_type_of(&stripped, ctx);
        }
        ctx->declare_local(p.name, alloca, pt, deref_t, is_unsigned_type_node(p.type));
    }

    // Emit body. visit_block_stmt pushes/pops its own scope for locals.
    visit_block_stmt(fd->body, ctx);

    // Add an implicit return if the last block has no terminator.
    if (!ctx->is_terminated()) {
        if (LLVMGetTypeKind(ctx->current_ret_type) == LLVMVoidTypeKind)
            LLVMBuildRetVoid(ctx->llvm_builder);
        else
            LLVMBuildUnreachable(ctx->llvm_builder);
    }

    ctx->pop_scope();
    ctx->current_func                = nullptr;
    ctx->current_func_type           = nullptr;
    ctx->current_ret_type            = nullptr;
    ctx->current_func_is_error_union = false;
    ctx->current_error_union_type    = nullptr;
    ctx->current_namespace           = saved_ns;
}

// ------------------------------------------------------------------ generic function instantiation

inline void emit_generic_func_instance(func_decl* fd,
                                       const std::vector<LLVMTypeRef>& targs,
                                       const std::string& mangled,
                                       ir_context* ctx) {
    // Install type-parameter substitution (preserving any outer substitution for nested generics).
    auto saved_subst = ctx->type_subst;
    for (size_t i = 0; i < fd->type_params.size() && i < targs.size(); ++i)
        ctx->type_subst[fd->type_params[i]] = targs[i];

    // Build the concrete signature.
    std::vector<LLVMTypeRef> param_types;
    for (auto& p : fd->params) param_types.push_back(llvm_type_of(p.type, ctx));
    LLVMTypeRef ret_t = llvm_type_of(fd->ret_type, ctx);
    LLVMTypeRef fn_t  = LLVMFunctionType(ret_t, param_types.data(),
                                         static_cast<unsigned>(param_types.size()),
                                         fd->is_variadic ? 1 : 0);
    LLVMValueRef fn = LLVMGetNamedFunction(ctx->llvm_mod, mangled.c_str());
    if (!fn) fn = LLVMAddFunction(ctx->llvm_mod, mangled.c_str(), fn_t);
    ctx->global_funcs[mangled]      = fn;
    ctx->global_func_types[mangled] = fn_t;

    if (fd->body) {
        // Save the current emission state (we may be nested inside another function).
        LLVMBasicBlockRef saved_bb  = LLVMGetInsertBlock(ctx->llvm_builder);
        LLVMValueRef       saved_fn  = ctx->current_func;
        LLVMTypeRef        saved_fnt = ctx->current_func_type;
        LLVMTypeRef        saved_ret = ctx->current_ret_type;
        std::vector<ir_scope_frame> saved_scopes; saved_scopes.swap(ctx->scopes);
        auto saved_defer = std::move(ctx->defer_stack); ctx->defer_stack.clear();

        ctx->current_func      = fn;
        ctx->current_func_type = fn_t;
        ctx->current_ret_type  = ret_t;

        LLVMBasicBlockRef entry = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "entry");
        LLVMPositionBuilderAtEnd(ctx->llvm_builder, entry);
        ctx->push_scope();

        for (unsigned i = 0; i < static_cast<unsigned>(fd->params.size()); ++i) {
            const auto& p  = fd->params[i];
            LLVMTypeRef pt = llvm_type_of(p.type, ctx);
            LLVMValueRef a = LLVMBuildAlloca(ctx->llvm_builder, pt, p.name.c_str());
            LLVMBuildStore(ctx->llvm_builder, LLVMGetParam(fn, i), a);
            LLVMTypeRef deref = nullptr;
            if (p.type->pointer_depth > 0) { type_node s = *p.type; s.pointer_depth--; deref = llvm_type_of(&s, ctx); }
            ctx->declare_local(p.name, a, pt, deref, is_unsigned_type_node(p.type));
        }

        visit_block_stmt(fd->body, ctx);

        if (!ctx->is_terminated()) {
            if (LLVMGetTypeKind(ret_t) == LLVMVoidTypeKind) LLVMBuildRetVoid(ctx->llvm_builder);
            else                                            LLVMBuildUnreachable(ctx->llvm_builder);
        }
        ctx->pop_scope();

        // Restore previous emission state.
        ctx->scopes.swap(saved_scopes);
        ctx->defer_stack       = std::move(saved_defer);
        ctx->current_func      = saved_fn;
        ctx->current_func_type = saved_fnt;
        ctx->current_ret_type  = saved_ret;
        if (saved_bb) LLVMPositionBuilderAtEnd(ctx->llvm_builder, saved_bb);
    }

    ctx->type_subst = saved_subst;
}

// ------------------------------------------------------------------ class (istruc)

// Forward declaration — maybe_instantiate_generic_type is defined later but called here.
inline void maybe_instantiate_generic_type(const type_node* t, ir_context* ctx);

inline void visit_class_decl_types(class_decl* d, ir_context* ctx) {
    ir_context::class_ir_info info;
    info.base_name = d->base_name;

    // Set namespace from the class's own mangled name so that unqualified generic
    // field types (e.g. "array<f32>" written inside namespace soa) can be resolved.
    std::string saved_ns = ctx->current_namespace;
    auto cls_ns_pos = d->name.rfind("__NS_");
    if (cls_ns_pos != std::string::npos) ctx->current_namespace = d->name.substr(0, cls_ns_pos);
    else ctx->current_namespace.clear();

    // Own fields only — inheritance and vtable are not supported
    std::vector<LLVMTypeRef>  all_field_types;
    std::vector<std::string>  all_field_names;
    std::vector<bool>         all_field_unsigned;
    std::vector<LLVMTypeRef>  all_field_pointee;

    for (auto* f : d->fields) {
        maybe_instantiate_generic_type(f->type, ctx); // ensure generic field types exist first
        all_field_names.push_back(f->name);
        all_field_types.push_back(llvm_type_of(f->type, ctx));
        all_field_unsigned.push_back(is_unsigned_type_node(f->type));
        if (f->type && f->type->pointer_depth > 0) {
            type_node stripped = *f->type;
            stripped.pointer_depth--;
            stripped.array_size = std::nullopt;
            all_field_pointee.push_back(llvm_type_of(&stripped, ctx));
        } else {
            all_field_pointee.push_back(nullptr);
        }
    }

    info.all_field_names = all_field_names;
    info.all_field_types = all_field_types;

    // Record method info for ifo_t reflection
    for (auto* m : d->methods) {
        ir_context::class_method_ir_info mi;
        mi.name        = m->name;
        mi.param_count = (int)m->params.size();
        mi.ret_type    = m->ret_type;
        info.methods.push_back(std::move(mi));
    }

    // Create the class struct type
    LLVMTypeRef class_t = LLVMStructCreateNamed(ctx->llvm_ctx, d->name.c_str());
    LLVMStructSetBody(class_t, all_field_types.data(),
                      static_cast<unsigned>(all_field_types.size()), 0);
    info.class_type = class_t;

    ctx->struct_types[d->name]          = class_t;
    ctx->struct_field_names[d->name]    = all_field_names;
    ctx->struct_field_types[d->name]    = all_field_types;
    ctx->struct_field_unsigned[d->name]       = std::move(all_field_unsigned);
    ctx->struct_field_pointee_types[d->name] = std::move(all_field_pointee);
    ctx->class_infos[d->name]                = std::move(info);

    ctx->current_namespace = saved_ns;
}

inline void visit_class_decl_methods_prototype(class_decl* d, ir_context* ctx) {
    // Set namespace context from class name; rfind gives deepest parent namespace for multi-level.
    std::string saved_cls_proto_ns = ctx->current_namespace;
    auto cls_ns_pos = d->name.rfind("__NS_");
    if (cls_ns_pos != std::string::npos) ctx->current_namespace = d->name.substr(0, cls_ns_pos);
    else ctx->current_namespace.clear();

    std::unordered_map<std::string, int> proto_name_occ;
    for (auto* m : d->methods) {
        // Build a synthetic func_decl and register its prototype
        std::string base_ir = m->mangled_name.empty() ? (d->name + "__MT_" + m->name) : m->mangled_name;
        int occ = proto_name_occ[base_ir]++;
        std::string ir_name = (occ > 0) ? (base_ir + "__OL" + std::to_string(occ)) : base_ir;

        std::vector<LLVMTypeRef> param_types;
        // Implicit self param (class pointer)
        if (m->has_self) {
            LLVMTypeRef self_t = LLVMPointerType(ctx->struct_types[d->name], 0);
            param_types.push_back(self_t);
        }
        for (auto& p : m->params)
            param_types.push_back(llvm_type_of(p.type, ctx));

        LLVMTypeRef ret_t = m->ret_type ? llvm_type_of(m->ret_type, ctx)
                                        : LLVMVoidTypeInContext(ctx->llvm_ctx);
        LLVMTypeRef fn_t  = LLVMFunctionType(ret_t, param_types.data(),
                                              static_cast<unsigned>(param_types.size()),
                                              m->is_variadic ? 1 : 0);
        LLVMValueRef fn = LLVMGetNamedFunction(ctx->llvm_mod, ir_name.c_str());
        if (!fn) fn = LLVMAddFunction(ctx->llvm_mod, ir_name.c_str(), fn_t);

        if (m->is_noexcept) {
            unsigned k = LLVMGetEnumAttributeKindForName("nounwind", 8);
            if (k) LLVMAddAttributeAtIndex(fn, LLVMAttributeFunctionIndex,
                       LLVMCreateEnumAttribute(ctx->llvm_ctx, k, 0));
        }

        ctx->global_funcs[ir_name]      = fn;
        ctx->global_func_types[ir_name] = fn_t;
    }
    // For memstr classes, emit a vtable global {mmap_fn, rmap_fn, deinit_fn}
    if (d->is_memstr) {
        LLVMTypeRef ptr_t = LLVMPointerTypeInContext(ctx->llvm_ctx, 0);
        if (!ctx->memstr_vtable_type) {
            LLVMTypeRef vfields[3] = {ptr_t, ptr_t, ptr_t};
            ctx->memstr_vtable_type = LLVMStructTypeInContext(ctx->llvm_ctx, vfields, 3, 0);
        }
        LLVMValueRef null_fn = LLVMConstNull(ptr_t);
        auto get_fn = [&](const std::string& n) -> LLVMValueRef {
            auto it = ctx->global_funcs.find(n);
            return (it != ctx->global_funcs.end()) ? it->second : null_fn;
        };
        LLVMValueRef vtable_vals[3] = {
            get_fn(d->name + "__MT_mmap"),
            get_fn(d->name + "__MT_rmap"),
            get_fn(d->name + "__MT_deinit")
        };
        LLVMValueRef vtable_init = LLVMConstStructInContext(ctx->llvm_ctx, vtable_vals, 3, 0);
        std::string vtable_name = d->name + "__vtable__";
        LLVMValueRef vtable_g = LLVMAddGlobal(ctx->llvm_mod, ctx->memstr_vtable_type, vtable_name.c_str());
        LLVMSetInitializer(vtable_g, vtable_init);
        LLVMSetGlobalConstant(vtable_g, 1);
        ctx->memstr_vtables[d->name] = vtable_g;
    }
    ctx->current_namespace = saved_cls_proto_ns;
}

inline void visit_class_decl_methods_body(class_decl* d, ir_context* ctx) {
    std::unordered_map<std::string, int> body_name_occ;
    for (auto* m : d->methods) {
        std::string base_ir = m->mangled_name.empty() ? (d->name + "__MT_" + m->name) : m->mangled_name;
        int occ = body_name_occ[base_ir]++;
        if (!m->body) continue;
        std::string ir_name = (occ > 0) ? (base_ir + "__OL" + std::to_string(occ)) : base_ir;
        LLVMValueRef fn   = ctx->global_funcs[ir_name];
        LLVMTypeRef  fn_t = ctx->global_func_types[ir_name];

        ctx->current_func       = fn;
        ctx->current_func_type  = fn_t;
        ctx->current_ret_type   = LLVMGetReturnType(fn_t);
        ctx->current_class_name = d->name;
        // Set namespace from class name; rfind gives deepest parent for multi-level namespaces.
        std::string saved_meth_ns = ctx->current_namespace;
        auto mns_pos = d->name.rfind("__NS_");
        if (mns_pos != std::string::npos) ctx->current_namespace = d->name.substr(0, mns_pos);
        else ctx->current_namespace.clear();

        LLVMBasicBlockRef entry_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "entry");
        LLVMPositionBuilderAtEnd(ctx->llvm_builder, entry_bb);
        ctx->push_scope();

        unsigned param_idx = 0;
        // Self parameter
        if (m->has_self) {
            LLVMTypeRef  struct_t = ctx->struct_types[d->name];
            LLVMTypeRef  self_t   = LLVMPointerType(struct_t, 0);
            const std::string& sname = m->self_param_name.empty() ? "self" : m->self_param_name;
            LLVMValueRef self_alloca = LLVMBuildAlloca(ctx->llvm_builder, self_t, (sname + ".addr").c_str());
            LLVMBuildStore(ctx->llvm_builder, LLVMGetParam(fn, param_idx), self_alloca);
            // deref_t = struct type so (*self).field and self.field can resolve the struct name
            ctx->declare_local(sname, self_alloca, self_t, struct_t);
            param_idx++;
        }
        // Regular parameters
        for (unsigned i = 0; i < static_cast<unsigned>(m->params.size()); i++, param_idx++) {
            const auto& p  = m->params[i];
            LLVMTypeRef pt = llvm_type_of(p.type, ctx);
            LLVMValueRef alloca = LLVMBuildAlloca(ctx->llvm_builder, pt, p.name.c_str());
            LLVMBuildStore(ctx->llvm_builder, LLVMGetParam(fn, param_idx), alloca);
            LLVMTypeRef deref_t = nullptr;
            if (p.type->pointer_depth > 0) {
                type_node stripped = *p.type; stripped.pointer_depth--;
                deref_t = llvm_type_of(&stripped, ctx);
            }
            ctx->declare_local(p.name, alloca, pt, deref_t, is_unsigned_type_node(p.type));
        }

        // Emit constructor init list before the body: self.member = value
        if (m->is_constructor && !m->init_list.empty()) {
            LLVMTypeRef struct_t = ctx->struct_types[d->name];
            const std::string& sn = m->self_param_name.empty() ? "self" : m->self_param_name;
            LLVMValueRef self_load = LLVMBuildLoad2(ctx->llvm_builder,
                LLVMPointerType(struct_t, 0), ctx->lookup_local(sn), sn.c_str());
            const auto& fnames = ctx->struct_field_names[d->name];
            for (auto& entry : m->init_list) {
                for (unsigned fi = 0; fi < fnames.size(); fi++) {
                    if (fnames[fi] == entry.member_name) {
                        LLVMValueRef indices[2] = {
                            LLVMConstInt(LLVMInt32TypeInContext(ctx->llvm_ctx), 0, 0),
                            LLVMConstInt(LLVMInt32TypeInContext(ctx->llvm_ctx), fi, 0)
                        };
                        LLVMValueRef field_ptr = LLVMBuildGEP2(ctx->llvm_builder, struct_t,
                            self_load, indices, 2, "initfield");
                        LLVMValueRef init_val = visit_expr(entry.value, ctx);
                        LLVMBuildStore(ctx->llvm_builder, init_val, field_ptr);
                        break;
                    }
                }
            }
        }

        visit_block_stmt(m->body, ctx);

        if (!ctx->is_terminated()) {
            if (LLVMGetTypeKind(ctx->current_ret_type) == LLVMVoidTypeKind)
                LLVMBuildRetVoid(ctx->llvm_builder);
            else
                LLVMBuildUnreachable(ctx->llvm_builder);
        }
        ctx->pop_scope();
        ctx->current_func       = nullptr;
        ctx->current_func_type  = nullptr;
        ctx->current_ret_type   = nullptr;
        ctx->current_class_name = "";
        ctx->current_namespace  = saved_meth_ns;
    }

}

// ------------------------------------------------------------------ generic class instantiation

// Instantiate a generic class template for a concrete set of type arguments by
// emitting a monomorphized struct type + methods under the mangled name.
inline void instantiate_generic_class(class_decl* tmpl,
                                      const std::vector<type_node*>& targs,
                                      const std::string& mangled,
                                      ir_context* ctx) {
    if (ctx->struct_types.count(mangled)) return; // already done

    auto saved_subst = ctx->type_subst;
    for (size_t i = 0; i < tmpl->type_params.size() && i < targs.size(); ++i)
        ctx->type_subst[tmpl->type_params[i]] = llvm_type_of(targs[i], ctx);

    // Temporarily rename the template so all emitted names use the mangled form.
    std::string orig_name = tmpl->name;
    tmpl->name = mangled;

    // Save builder/emission state (we may be mid-function).
    LLVMBasicBlockRef saved_bb  = LLVMGetInsertBlock(ctx->llvm_builder);
    LLVMValueRef       saved_fn  = ctx->current_func;
    LLVMTypeRef        saved_fnt = ctx->current_func_type;
    LLVMTypeRef        saved_ret = ctx->current_ret_type;
    std::string        saved_cls = ctx->current_class_name;
    std::vector<ir_scope_frame> saved_scopes; saved_scopes.swap(ctx->scopes);
    auto saved_defer = std::move(ctx->defer_stack); ctx->defer_stack.clear();

    visit_class_decl_types(tmpl, ctx);
    visit_class_decl_methods_prototype(tmpl, ctx);
    visit_class_decl_methods_body(tmpl, ctx);

    ctx->scopes.swap(saved_scopes);
    ctx->defer_stack       = std::move(saved_defer);
    ctx->current_func      = saved_fn;
    ctx->current_func_type = saved_fnt;
    ctx->current_ret_type  = saved_ret;
    ctx->current_class_name = saved_cls;
    if (saved_bb) LLVMPositionBuilderAtEnd(ctx->llvm_builder, saved_bb);

    tmpl->name      = orig_name;
    ctx->type_subst = saved_subst;
}

// If `t` references a generic class with concrete type args, ensure it is instantiated.
inline void maybe_instantiate_generic_type(const type_node* t, ir_context* ctx) {
    if (!t || t->is_primitive || !t->name || t->type_args.empty()) return;
    auto git = ctx->generic_classes.find(*t->name);
    // If unqualified name not found, try namespace-qualified (e.g. "array" → "std__NS_soa__NS_array")
    if (git == ctx->generic_classes.end() && !ctx->current_namespace.empty())
        git = ctx->generic_classes.find(ctx->current_namespace + "__NS_" + *t->name);
    if (git == ctx->generic_classes.end()) return;
    // Use the map key (fully qualified name) for the mangled name so it matches llvm_type_of lookup.
    std::string mangled = generic_class_mangled(git->first, t->type_args);
    if (!ctx->struct_types.count(mangled))
        instantiate_generic_class(git->second, t->type_args, mangled, ctx);
}

// ------------------------------------------------------------------ extern "C" block

inline void visit_extern_c_block(extern_c_block* blk, ir_context* ctx) {
    for (auto* decl : blk->decls)
        visit_top_level_decl(decl, ctx);
}

// ------------------------------------------------------------------ top-level dispatcher

inline void visit_top_level_decl(ast_node* node, ir_context* ctx) {
    if (auto* d = dynamic_cast<struct_decl*>(node))   { visit_struct_decl(d, ctx);   return; }
    if (auto* d = dynamic_cast<union_decl*>(node))    { visit_union_decl(d, ctx);    return; }
    if (auto* d = dynamic_cast<enum_decl*>(node))     { visit_enum_decl(d, ctx);     return; }
    if (auto* d = dynamic_cast<typedef_decl*>(node))  { visit_typedef_decl(d, ctx);  return; }
    if (auto* d = dynamic_cast<var_decl*>(node))      { visit_global_var_decl(d, ctx); return; }
    if (auto* d = dynamic_cast<func_decl*>(node))     { visit_func_decl(d, ctx);     return; }
    if (auto* d = dynamic_cast<class_decl*>(node))    { /* handled in two-pass */ (void)d; return; }
    if (auto* d = dynamic_cast<extern_c_block*>(node)){ visit_extern_c_block(d, ctx); return; }
    if (dynamic_cast<memstr_decl*>(node))               { return; } // stub
    if (dynamic_cast<namespace_decl*>(node))            { return; } // already flattened
    throw std::runtime_error("IR: Unknown top-level declaration kind");
}

// ------------------------------------------------------------------ program

// Collect all nodes in extern "C" blocks and namespaces, flattened
static void flatten_extern_c(ast_node* node, std::vector<ast_node*>& out) {
    if (auto* blk = dynamic_cast<extern_c_block*>(node)) {
        for (auto* d : blk->decls) flatten_extern_c(d, out);
    } else if (auto* ns = dynamic_cast<namespace_decl*>(node)) {
        for (auto* d : ns->decls) flatten_extern_c(d, out);
    } else {
        out.push_back(node);
    }
}

inline void visit_program(program_node* prog, ir_context* ctx) {
    // Flatten extern "C" blocks for uniform processing
    std::vector<ast_node*> all_decls;
    for (auto* node : prog->decls) flatten_extern_c(node, all_decls);

    // Pass 0: Register generic templates; they are emitted lazily on first use.
    for (auto* node : all_decls) {
        if (auto* d = dynamic_cast<func_decl*>(node))  { if (!d->type_params.empty()) ctx->generic_funcs[d->name]  = d; continue; }
        if (auto* d = dynamic_cast<class_decl*>(node)) { if (!d->type_params.empty()) ctx->generic_classes[d->name] = d; continue; }
    }

    // Pre-init &memstr fat/vtable types. Generic method bodies (compiled during pass 1a
    // via instantiate_generic_class) may contain `a.mmap(n)` style calls, which require
    // these types to emit correct vtable dispatch IR. Doing this eagerly avoids order
    // dependence on when the first concrete memstr class (bump/slab/arena) is processed.
    {
        LLVMTypeRef ptr_t = LLVMPointerTypeInContext(ctx->llvm_ctx, 0);
        if (!ctx->memstr_fat_type) {
            ctx->memstr_fat_type = LLVMStructCreateNamed(ctx->llvm_ctx, "__memstr_fat__");
            LLVMTypeRef fields[2] = {ptr_t, ptr_t};
            LLVMStructSetBody(ctx->memstr_fat_type, fields, 2, 0);
        }
        if (!ctx->memstr_vtable_type) {
            LLVMTypeRef vfields[3] = {ptr_t, ptr_t, ptr_t};
            ctx->memstr_vtable_type = LLVMStructTypeInContext(ctx->llvm_ctx, vfields, 3, 0);
        }
    }

    // Pass 0.5: Collect constexpr integer values so that llvm_type_of can resolve
    // identifier-based array sizes (e.g. void* field_ptrs[SOA_MAX_FIELDS]) during pass 1a.
    for (auto* node : all_decls) {
        auto* d = dynamic_cast<var_decl*>(node);
        if (!d || !d->is_constexpr || !d->init.has_value()) continue;
        expr_node* iv = d->init.value();
        int64_t val = 0;
        bool ok = false;
        if (iv && iv->kind == expr_kind::int_lit) { val = iv->int_val; ok = true; }
        // Also handle (CastType)int_lit
        else if (iv && iv->kind == expr_kind::cast && iv->object && iv->object->kind == expr_kind::int_lit)
            { val = iv->object->int_val; ok = true; }
        if (ok) ctx->constexpr_int_vals[d->name] = val;
    }

    // Pass 1a: Register all struct/union/enum/typedef types (including class types)
    for (auto* node : all_decls) {
        if (auto* d = dynamic_cast<struct_decl*>(node))  { visit_struct_decl(d, ctx);  continue; }
        if (auto* d = dynamic_cast<union_decl*>(node))   { visit_union_decl(d, ctx);   continue; }
        if (auto* d = dynamic_cast<enum_decl*>(node))    { visit_enum_decl(d, ctx);    continue; }
        if (auto* d = dynamic_cast<typedef_decl*>(node)) { visit_typedef_decl(d, ctx); continue; }
        if (auto* d = dynamic_cast<class_decl*>(node))   { if (d->type_params.empty()) visit_class_decl_types(d, ctx); continue; }
    }

    // Pass 1a.5: Register istruc_body variants of ADT enums as class types
    // (so their methods can be called like istruc methods)
    for (auto* node : all_decls) {
        if (auto* d = dynamic_cast<enum_decl*>(node)) {
            if (!d->is_adt) continue;
            for (auto* ev : d->variants) {
                if (ev->kind == enum_variant_kind::istruc_body && ev->istruc_body) {
                    // Use the enum's LLVM type as the class type (ADT struct reuse)
                    // Register the ADT struct type under the variant name so method
                    // prototypes (which use d->name) can look it up via struct_types.
                    ctx->struct_types[ev->istruc_body->name] = ctx->struct_types[d->name];

                    auto& info = ctx->class_infos[ev->istruc_body->name];
                    info.class_type = ctx->struct_types[d->name];
                    info.base_name  = "";
                    // Field layout: tag + fields
                    info.all_field_names = {"__tag"};
                    info.all_field_types = {LLVMInt32TypeInContext(ctx->llvm_ctx)};
                    for (auto* cf : ev->istruc_body->fields) {
                        info.all_field_names.push_back(cf->name);
                        info.all_field_types.push_back(llvm_type_of(cf->type, ctx));
                    }
                    ctx->struct_field_names[ev->istruc_body->name] = info.all_field_names;
                    ctx->struct_field_types[ev->istruc_body->name] = info.all_field_types;
                }
            }
        }
    }

    // Pass 1b: Register function/method prototypes (after types are known)
    for (auto* node : all_decls) {
        if (auto* d = dynamic_cast<func_decl*>(node))  { if (d->type_params.empty()) visit_func_decl_prototype(d, ctx); continue; }
        if (auto* d = dynamic_cast<class_decl*>(node)) { if (d->type_params.empty()) visit_class_decl_methods_prototype(d, ctx); continue; }
    }
    // Pass 1b.5: Register derive-synthesised function prototypes so pass-2 bodies can call them.
    for (auto* node : all_decls) {
        auto* d = dynamic_cast<class_decl*>(node);
        if (!d || !d->type_params.empty()) continue;
        auto it_cls = ctx->class_infos.find(d->name);
        if (it_cls == ctx->class_infos.end()) continue;
        LLVMTypeRef cls_ty  = it_cls->second.class_type;
        LLVMTypeRef ptr_ty  = LLVMPointerType(cls_ty, 0);
        LLVMTypeRef void_ty = LLVMVoidTypeInContext(ctx->llvm_ctx);
        for (auto& attr : d->attributes) {
            if (attr.name != "derive") continue;
            for (auto& dname : attr.args) {
                std::string fn_name;
                LLVMTypeRef fn_ty = nullptr;
                if (dname == "Debug") {
                    fn_name = "__derive_Debug_" + d->name;
                    fn_ty   = LLVMFunctionType(void_ty, &ptr_ty, 1, 0);
                } else if (dname == "Clone") {
                    fn_name = "__derive_Clone_" + d->name;
                    fn_ty   = LLVMFunctionType(cls_ty, &ptr_ty, 1, 0);
                } else if (dname == "Default") {
                    fn_name = "__derive_Default_" + d->name;
                    fn_ty   = LLVMFunctionType(cls_ty, nullptr, 0, 0);
                }
                if (fn_ty && !ctx->global_funcs.count(fn_name)) {
                    LLVMValueRef fn = LLVMAddFunction(ctx->llvm_mod, fn_name.c_str(), fn_ty);
                    ctx->global_funcs[fn_name]      = fn;
                    ctx->global_func_types[fn_name] = fn_ty;
                }
            }
        }
    }
    // Register istruc_body variant method prototypes
    for (auto* node : all_decls) {
        if (auto* d = dynamic_cast<enum_decl*>(node)) {
            if (!d->is_adt) continue;
            for (auto* ev : d->variants) {
                if (ev->kind == enum_variant_kind::istruc_body && ev->istruc_body)
                    visit_class_decl_methods_prototype(ev->istruc_body, ctx);
            }
        }
    }

    // Generate wrapper ctors for istruc_body variants that have a user-defined __construct__.
    // Must run after method prototypes are registered so the __construct__ fn is in global_funcs.
    for (auto* node : all_decls) {
        auto* d = dynamic_cast<enum_decl*>(node);
        if (!d || !d->is_adt) continue;
        LLVMTypeRef adt_t = ctx->struct_types.count(d->name) ? ctx->struct_types[d->name] : nullptr;
        if (!adt_t) continue;
        LLVMTypeRef i32t = LLVMInt32TypeInContext(ctx->llvm_ctx);
        int tag_idx = 0;
        for (auto* ev : d->variants) {
            if (ev->kind != enum_variant_kind::istruc_body || !ev->istruc_body) { tag_idx++; continue; }
            // Find user-defined __construct__
            class_method* user_ctor = nullptr;
            for (auto* m : ev->istruc_body->methods)
                if (m->name == "__construct__") { user_ctor = m; break; }
            if (!user_ctor) { tag_idx++; continue; }
            // Look up the registered __construct__ function
            std::string ctor_mt = ev->istruc_body->name + "__MT___construct__";
            auto mt_it = ctx->global_funcs.find(ctor_mt);
            if (mt_it == ctx->global_funcs.end()) { tag_idx++; continue; }
            LLVMValueRef ctor_fn = mt_it->second;
            LLVMTypeRef  ctor_ft = ctx->global_func_types[ctor_mt];
            unsigned nparams = LLVMCountParamTypes(ctor_ft); // includes self as first param

            // Build wrapper param types: __construct__ params minus self (param 0)
            std::vector<LLVMTypeRef> all_pts(nparams > 0 ? nparams : 1);
            if (nparams) LLVMGetParamTypes(ctor_ft, all_pts.data());
            std::vector<LLVMTypeRef> wrap_params;
            for (unsigned i = 1; i < nparams; i++) wrap_params.push_back(all_pts[i]);

            std::string wrap_name = d->name + "__" + ev->name + "__ctor";
            // Skip if already registered (e.g. redeclaration)
            if (ctx->global_funcs.count(wrap_name)) { tag_idx++; continue; }

            LLVMTypeRef wrap_fn_t = LLVMFunctionType(adt_t,
                wrap_params.empty() ? nullptr : wrap_params.data(),
                (unsigned)wrap_params.size(), 0);
            LLVMValueRef wrap_fn = LLVMAddFunction(ctx->llvm_mod, wrap_name.c_str(), wrap_fn_t);

            LLVMBasicBlockRef bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, wrap_fn, "entry");
            LLVMPositionBuilderAtEnd(ctx->llvm_builder, bb);

            // Allocate the ADT struct, set tag
            LLVMValueRef alloca = LLVMBuildAlloca(ctx->llvm_builder, adt_t, "adt");
            LLVMBuildStore(ctx->llvm_builder, LLVMConstNull(adt_t), alloca);
            LLVMValueRef tag_ptr = LLVMBuildStructGEP2(ctx->llvm_builder, adt_t, alloca, 0, "tagp");
            LLVMBuildStore(ctx->llvm_builder, LLVMConstInt(i32t, tag_idx, 0), tag_ptr);

            // Call __construct__(alloca, user_args...)
            std::vector<LLVMValueRef> cargs;
            cargs.push_back(alloca);
            for (unsigned i = 0; i < (unsigned)wrap_params.size(); i++)
                cargs.push_back(LLVMGetParam(wrap_fn, i));
            LLVMBuildCall2(ctx->llvm_builder, ctor_ft, ctor_fn,
                           cargs.data(), (unsigned)cargs.size(), "");

            LLVMValueRef ret_v = LLVMBuildLoad2(ctx->llvm_builder, adt_t, alloca, "adtv");
            LLVMBuildRet(ctx->llvm_builder, ret_v);

            ctx->global_funcs[wrap_name]      = wrap_fn;
            ctx->global_func_types[wrap_name] = wrap_fn_t;
            tag_idx++;
        }
    }

    // Pass 2: Emit global variables and function/method bodies
    for (auto* node : all_decls) {
        if (auto* d = dynamic_cast<var_decl*>(node))   { visit_global_var_decl(d, ctx);      continue; }
        if (auto* d = dynamic_cast<func_decl*>(node))  {
            // Proc macro function bodies execute before the compiler, not in IR.
            if (d->pm_kind != func_decl::proc_macro_kind::none) continue;
            if (d->type_params.empty()) visit_func_decl(d, ctx);
            continue;
        }
        if (auto* d = dynamic_cast<class_decl*>(node)) { if (d->type_params.empty()) visit_class_decl_methods_body(d, ctx); continue; }
    }
    // Emit istruc_body variant method bodies
    for (auto* node : all_decls) {
        if (auto* d = dynamic_cast<enum_decl*>(node)) {
            if (!d->is_adt) continue;
            for (auto* ev : d->variants) {
                if (ev->kind == enum_variant_kind::istruc_body && ev->istruc_body)
                    visit_class_decl_methods_body(ev->istruc_body, ctx);
            }
        }
    }

    // Pass 3: Emit built-in derive-macro functions for classes with #[derive(...)]
    for (auto* node : all_decls) {
        auto* d = dynamic_cast<class_decl*>(node);
        if (!d || d->type_params.size() > 0) continue;
        for (auto& attr : d->attributes) {
            if (attr.name != "derive") continue;
            auto it_cls = ctx->class_infos.find(d->name);
            if (it_cls == ctx->class_infos.end()) continue;
            LLVMTypeRef cls_ty = it_cls->second.class_type;

            for (auto& derive_name : attr.args) {
                // Pass 1b.5 already registered prototypes; here we fill in the bodies.
                // Guard: only emit a body if the function doesn't yet have one.
                auto body_needed = [&](const std::string& fn_name) -> LLVMValueRef {
                    auto it = ctx->global_funcs.find(fn_name);
                    if (it == ctx->global_funcs.end()) return nullptr;
                    if (LLVMCountBasicBlocks(it->second) > 0) return nullptr; // already has a body
                    return it->second;
                };

                if (derive_name == "Debug") {
                    std::string fn_name = "__derive_Debug_" + d->name;
                    LLVMValueRef fn = body_needed(fn_name);
                    if (!fn) {
                        LLVMTypeRef ptr_ty = LLVMPointerType(cls_ty, 0);
                        LLVMTypeRef fn_ty  = LLVMFunctionType(LLVMVoidTypeInContext(ctx->llvm_ctx), &ptr_ty, 1, 0);
                        fn = LLVMAddFunction(ctx->llvm_mod, fn_name.c_str(), fn_ty);
                        ctx->global_funcs[fn_name]      = fn;
                        ctx->global_func_types[fn_name] = fn_ty;
                    }
                    if (fn) {
                        LLVMBasicBlockRef bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "entry");
                        LLVMPositionBuilderAtEnd(ctx->llvm_builder, bb);
                        LLVMBuildRetVoid(ctx->llvm_builder);
                    }
                } else if (derive_name == "Clone") {
                    std::string fn_name = "__derive_Clone_" + d->name;
                    LLVMValueRef fn = body_needed(fn_name);
                    if (!fn) {
                        LLVMTypeRef ptr_ty = LLVMPointerType(cls_ty, 0);
                        LLVMTypeRef fn_ty  = LLVMFunctionType(cls_ty, &ptr_ty, 1, 0);
                        fn = LLVMAddFunction(ctx->llvm_mod, fn_name.c_str(), fn_ty);
                        ctx->global_funcs[fn_name]      = fn;
                        ctx->global_func_types[fn_name] = fn_ty;
                    }
                    if (fn) {
                        LLVMBasicBlockRef bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "entry");
                        LLVMPositionBuilderAtEnd(ctx->llvm_builder, bb);
                        LLVMValueRef self_ptr = LLVMGetParam(fn, 0);
                        LLVMValueRef loaded   = LLVMBuildLoad2(ctx->llvm_builder, cls_ty, self_ptr, "self_val");
                        LLVMBuildRet(ctx->llvm_builder, loaded);
                    }
                } else if (derive_name == "Default") {
                    std::string fn_name = "__derive_Default_" + d->name;
                    LLVMValueRef fn = body_needed(fn_name);
                    if (!fn) {
                        LLVMTypeRef fn_ty = LLVMFunctionType(cls_ty, nullptr, 0, 0);
                        fn = LLVMAddFunction(ctx->llvm_mod, fn_name.c_str(), fn_ty);
                        ctx->global_funcs[fn_name]      = fn;
                        ctx->global_func_types[fn_name] = fn_ty;
                    }
                    if (fn) {
                        LLVMBasicBlockRef bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "entry");
                        LLVMPositionBuilderAtEnd(ctx->llvm_builder, bb);
                        LLVMBuildRet(ctx->llvm_builder, LLVMConstNull(cls_ty));
                    }
                }
            }
        }
    }
}
