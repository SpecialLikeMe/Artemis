#pragma once
#include "stmts.hxx"
#include "names.hxx"

// Forward declare the top-level dispatcher.
inline void visit_top_level_decl(ast_node* node, ir_context* ctx);
inline void visit_func_decl_prototype(func_decl* fd, ir_context* ctx);

// ------------------------------------------------------------------ struct

inline void visit_struct_decl(struct_decl* d, ir_context* ctx) {
    // Create an opaque named struct type, then fill in its body.
    LLVMTypeRef struct_t = LLVMStructCreateNamed(ctx->llvm_ctx, d->name.c_str());

    std::vector<LLVMTypeRef> field_types;
    std::vector<std::string> field_names;

    for (auto* f : d->fields) {
        field_types.push_back(llvm_type_of(f->type, ctx));
        field_names.push_back(f->name);
    }

    LLVMStructSetBody(struct_t,
                      field_types.data(),
                      static_cast<unsigned>(field_types.size()),
                      /*packed=*/0);

    ctx->struct_types[d->name]       = struct_t;
    ctx->struct_field_names[d->name] = std::move(field_names);
    ctx->struct_field_types[d->name] = std::move(field_types);
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

    ctx->struct_types[d->name]       = union_t;
    ctx->struct_field_names[d->name] = std::move(field_names);
    ctx->struct_field_types[d->name] = std::move(field_types_vec);
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
            if (ev->istruc_body)
                for (auto* cf : ev->istruc_body->fields) {
                    params.push_back(llvm_type_of(cf->type, ctx));
                    pnames.push_back(cf->name);
                }
            break;
        default: break;
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
}

// ------------------------------------------------------------------ function (pass 1: declare signature)

inline void visit_func_decl_prototype(func_decl* fd, ir_context* ctx) {
    std::vector<LLVMTypeRef> param_types;
    for (auto& p : fd->params)
        param_types.push_back(llvm_type_of(p.type, ctx));

    LLVMTypeRef ret_t  = llvm_type_of(fd->ret_type, ctx);
    LLVMTypeRef fn_t   = LLVMFunctionType(ret_t,
                                           param_types.data(),
                                           static_cast<unsigned>(param_types.size()),
                                           fd->is_variadic ? 1 : 0);

    const std::string ir_name = ir_func_name(fd);

    // Reuse an existing declaration if already registered.
    LLVMValueRef fn = LLVMGetNamedFunction(ctx->llvm_mod, ir_name.c_str());
    if (!fn) fn = LLVMAddFunction(ctx->llvm_mod, ir_name.c_str(), fn_t);

    ctx->global_funcs[ir_name]      = fn;
    ctx->global_func_types[ir_name] = fn_t;
    // Also index by original name for single-overload functions
    if (ir_name != fd->name) {
        ctx->global_funcs[fd->name]      = fn;
        ctx->global_func_types[fd->name] = fn_t;
    }
}

// ------------------------------------------------------------------ function (pass 2: emit body)

inline void visit_func_decl(func_decl* fd, ir_context* ctx) {
    const std::string ir_name = ir_func_name(fd);
    // Prototype is already registered; grab it.
    LLVMValueRef fn   = ctx->global_funcs[ir_name];
    LLVMTypeRef  fn_t = ctx->global_func_types[ir_name];

    if (!fd->body) return; // forward declaration — nothing to emit

    ctx->current_func      = fn;
    ctx->current_func_type = fn_t;
    ctx->current_ret_type  = LLVMGetReturnType(fn_t);

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
        ctx->declare_local(p.name, alloca, pt, deref_t);
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
    ctx->current_func      = nullptr;
    ctx->current_func_type = nullptr;
    ctx->current_ret_type  = nullptr;
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
            ctx->declare_local(p.name, a, pt, deref);
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

inline void visit_class_decl_types(class_decl* d, ir_context* ctx) {
    ir_context::class_ir_info info;
    info.base_name  = d->base_name;
    info.has_virtual = d->has_virtual;

    // Build field layout: vtable ptr (if virtual) + base fields (if any) + own fields
    std::vector<LLVMTypeRef>  all_field_types;
    std::vector<std::string>  all_field_names;

    // Inherit base class fields
    if (!d->base_name.empty()) {
        auto it = ctx->class_infos.find(d->base_name);
        if (it != ctx->class_infos.end()) {
            auto& base = it->second;
            // Skip vtable ptr from base (we'll add our own)
            size_t start = base.has_virtual ? 1 : 0;
            for (size_t i = start; i < base.all_field_names.size(); i++) {
                all_field_names.push_back(base.all_field_names[i]);
                all_field_types.push_back(base.all_field_types[i]);
            }
        }
    }

    // Own fields
    for (auto* f : d->fields) {
        all_field_names.push_back(f->name);
        all_field_types.push_back(llvm_type_of(f->type, ctx));
    }

    // Collect virtual methods for vtable
    std::vector<std::string> vtable_slots;
    std::vector<LLVMTypeRef> vtable_fn_types;

    // Inherit vtable slots from base
    if (!d->base_name.empty()) {
        auto it = ctx->class_infos.find(d->base_name);
        if (it != ctx->class_infos.end()) {
            vtable_slots = it->second.vtable_slots;
        }
    }

    // Add/override virtual methods.
    // Strict rules: a method is virtual only if it is explicitly 'virtual'
    // (or 'mandatory virtual'), OR it is 'override'/'final' of a method that
    // already occupies a base vtable slot. Non-overriding plain methods in a
    // derived class are NOT virtual.
    for (auto* m : d->methods) {
        bool overrides_base = false;
        for (auto& slot : vtable_slots)
            if (slot == m->name) { overrides_base = true; break; }

        bool explicit_virtual = m->is_mandatory_virtual ||
                                (m->is_virtual && !m->is_override && !m->is_final);
        bool valid_override    = (m->is_override || m->is_final) && overrides_base;

        if (!explicit_virtual && !valid_override) continue; // not virtual here
        if (!overrides_base) vtable_slots.push_back(m->name); // new virtual slot
    }

    info.vtable_slots = vtable_slots;

    if (!vtable_slots.empty()) {
        info.has_virtual = true;
        // Build vtable struct type: { ret1 (ClassPtr)*, ret2 (ClassPtr)*, ... }
        // We need forward reference to the class type, so use opaque ptr for self
        LLVMTypeRef self_ptr_t = LLVMPointerType(LLVMInt8TypeInContext(ctx->llvm_ctx), 0);
        std::vector<LLVMTypeRef> vtbl_slot_types;
        for (auto& slot_name : vtable_slots) {
            // Find the method
            class_method* meth = nullptr;
            for (auto* m : d->methods)
                if (m->name == slot_name) { meth = m; break; }
            LLVMTypeRef ret_t = LLVMVoidTypeInContext(ctx->llvm_ctx);
            if (meth && meth->ret_type) ret_t = llvm_type_of(meth->ret_type, ctx);
            std::vector<LLVMTypeRef> fn_params = { self_ptr_t };
            if (meth) {
                for (auto& p : meth->params)
                    fn_params.push_back(llvm_type_of(p.type, ctx));
            }
            LLVMTypeRef fn_t = LLVMFunctionType(ret_t, fn_params.data(),
                                                 static_cast<unsigned>(fn_params.size()), 0);
            vtbl_slot_types.push_back(LLVMPointerType(fn_t, 0));
        }
        std::string vtbl_name = d->name + "_vtable_t";
        LLVMTypeRef vtbl_t = LLVMStructCreateNamed(ctx->llvm_ctx, vtbl_name.c_str());
        LLVMStructSetBody(vtbl_t, vtbl_slot_types.data(),
                          static_cast<unsigned>(vtbl_slot_types.size()), 0);
        info.vtable_type = vtbl_t;

        // Add vtable pointer as first field in class struct
        all_field_names.insert(all_field_names.begin(), "__vtbl");
        all_field_types.insert(all_field_types.begin(),
                               LLVMPointerType(vtbl_t, 0));
    }

    info.all_field_names = all_field_names;
    info.all_field_types = all_field_types;

    // Create the class struct type
    LLVMTypeRef class_t = LLVMStructCreateNamed(ctx->llvm_ctx, d->name.c_str());
    LLVMStructSetBody(class_t, all_field_types.data(),
                      static_cast<unsigned>(all_field_types.size()), 0);
    info.class_type = class_t;

    ctx->struct_types[d->name]       = class_t;
    ctx->struct_field_names[d->name] = all_field_names;
    ctx->struct_field_types[d->name] = all_field_types;
    ctx->class_infos[d->name]        = std::move(info);
}

inline void visit_class_decl_methods_prototype(class_decl* d, ir_context* ctx) {
    for (auto* m : d->methods) {
        // Build a synthetic func_decl and register its prototype
        std::string ir_name = m->mangled_name.empty() ? (d->name + "__MT_" + m->name) : m->mangled_name;

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

        ctx->global_funcs[ir_name]      = fn;
        ctx->global_func_types[ir_name] = fn_t;
    }
}

inline void visit_class_decl_methods_body(class_decl* d, ir_context* ctx) {
    for (auto* m : d->methods) {
        if (!m->body) continue;

        std::string ir_name = m->mangled_name.empty() ? (d->name + "__MT_" + m->name) : m->mangled_name;
        LLVMValueRef fn   = ctx->global_funcs[ir_name];
        LLVMTypeRef  fn_t = ctx->global_func_types[ir_name];

        ctx->current_func       = fn;
        ctx->current_func_type  = fn_t;
        ctx->current_ret_type   = LLVMGetReturnType(fn_t);
        ctx->current_class_name = d->name;

        LLVMBasicBlockRef entry_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "entry");
        LLVMPositionBuilderAtEnd(ctx->llvm_builder, entry_bb);
        ctx->push_scope();

        unsigned param_idx = 0;
        // Self parameter
        if (m->has_self) {
            LLVMTypeRef  struct_t = ctx->struct_types[d->name];
            LLVMTypeRef  self_t   = LLVMPointerType(struct_t, 0);
            LLVMValueRef self_alloca = LLVMBuildAlloca(ctx->llvm_builder, self_t, "self.addr");
            LLVMBuildStore(ctx->llvm_builder, LLVMGetParam(fn, param_idx), self_alloca);
            // deref_t = struct type so (*self).field and self->field can resolve the struct name
            ctx->declare_local("self", self_alloca, self_t, struct_t);
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
            ctx->declare_local(p.name, alloca, pt, deref_t);
        }

        // Emit constructor init list before the body: self.member = value
        if (m->is_constructor && !m->init_list.empty()) {
            LLVMTypeRef struct_t = ctx->struct_types[d->name];
            LLVMValueRef self_load = LLVMBuildLoad2(ctx->llvm_builder,
                LLVMPointerType(struct_t, 0), ctx->lookup_local("self"), "self");
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
    }

    // Create vtable global if needed
    auto& info = ctx->class_infos[d->name];
    if (info.vtable_type && !info.vtable_slots.empty()) {
        std::vector<LLVMValueRef> vtbl_values;
        for (auto& slot_name : info.vtable_slots) {
            std::string slot_ir = d->name + "__MT_" + slot_name;
            auto it = ctx->global_funcs.find(slot_ir);
            if (it != ctx->global_funcs.end()) {
                vtbl_values.push_back(it->second);
            } else {
                vtbl_values.push_back(LLVMConstNull(
                    LLVMGetElementType(LLVMStructGetTypeAtIndex(info.vtable_type,
                        static_cast<unsigned>(vtbl_values.size())))));
            }
        }
        std::string gname = d->name + "_vtable";
        LLVMValueRef vtbl_g = LLVMAddGlobal(ctx->llvm_mod, info.vtable_type, gname.c_str());
        LLVMSetInitializer(vtbl_g, LLVMConstNamedStruct(info.vtable_type,
                                                          vtbl_values.data(),
                                                          static_cast<unsigned>(vtbl_values.size())));
        LLVMSetGlobalConstant(vtbl_g, 1);
        info.vtable_global = vtbl_g;
        ctx->global_vars[gname] = vtbl_g;
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
    if (git == ctx->generic_classes.end()) return;
    std::string mangled = generic_class_mangled(*t->name, t->type_args);
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
                    info.has_virtual = false;
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

    // Pass 2: Emit global variables and function/method bodies
    for (auto* node : all_decls) {
        if (auto* d = dynamic_cast<var_decl*>(node))   { visit_global_var_decl(d, ctx);      continue; }
        if (auto* d = dynamic_cast<func_decl*>(node))  { if (d->type_params.empty()) visit_func_decl(d, ctx); continue; }
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
}
