#pragma once
#include "stmts.hxx"

// Forward declare the top-level dispatcher.
inline void visit_top_level_decl(ast_node* node, ir_context* ctx);

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

    ctx->struct_types[d->name]       = union_t;
    ctx->struct_field_names[d->name] = std::move(field_names);
}

// ------------------------------------------------------------------ enum

inline void visit_enum_decl(enum_decl* d, ir_context* ctx) {
    // Enum variants become i32 global constants.
    LLVMTypeRef i32 = LLVMInt32TypeInContext(ctx->llvm_ctx);
    int next_val = 0;

    for (auto& [name, init_expr] : d->variants) {
        if (init_expr.has_value()) {
            LLVMValueRef cv = visit_expr(init_expr.value(), ctx);
            // Extract constant value when possible.
            if (LLVMIsConstant(cv))
                next_val = static_cast<int>(LLVMConstIntGetSExtValue(cv));
        }

        LLVMValueRef global = LLVMAddGlobal(ctx->llvm_mod, i32, name.c_str());
        LLVMSetInitializer(global, LLVMConstInt(i32, next_val, /*sign-extend=*/1));
        LLVMSetGlobalConstant(global, 1);
        LLVMSetLinkage(global, LLVMInternalLinkage);

        ctx->global_vars[name] = global;
        next_val++;
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
    }
    // Primitive typedefs don't need special registration; llvm_type_of handles them.
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

    // Reuse an existing declaration if already registered.
    LLVMValueRef fn = LLVMGetNamedFunction(ctx->llvm_mod, fd->name.c_str());
    if (!fn) fn = LLVMAddFunction(ctx->llvm_mod, fd->name.c_str(), fn_t);

    ctx->global_funcs[fd->name]      = fn;
    ctx->global_func_types[fd->name] = fn_t;
}

// ------------------------------------------------------------------ function (pass 2: emit body)

inline void visit_func_decl(func_decl* fd, ir_context* ctx) {
    // Prototype is already registered; grab it.
    LLVMValueRef fn   = ctx->global_funcs[fd->name];
    LLVMTypeRef  fn_t = ctx->global_func_types[fd->name];

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
        LLVMTypeRef deref_t = nullptr;
        if (p.type->pointer_depth > 0) {
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

// ------------------------------------------------------------------ top-level dispatcher

inline void visit_top_level_decl(ast_node* node, ir_context* ctx) {
    if (auto* d = dynamic_cast<struct_decl*>(node))  { visit_struct_decl(d, ctx);   return; }
    if (auto* d = dynamic_cast<union_decl*>(node))   { visit_union_decl(d, ctx);    return; }
    if (auto* d = dynamic_cast<enum_decl*>(node))    { visit_enum_decl(d, ctx);     return; }
    if (auto* d = dynamic_cast<typedef_decl*>(node)) { visit_typedef_decl(d, ctx);  return; }
    if (auto* d = dynamic_cast<var_decl*>(node))     { visit_global_var_decl(d, ctx); return; }
    if (auto* d = dynamic_cast<func_decl*>(node))    { visit_func_decl(d, ctx);     return; }
    throw std::runtime_error("IR: Unknown top-level declaration kind");
}

// ------------------------------------------------------------------ program

inline void visit_program(program_node* prog, ir_context* ctx) {
    // Pass 1: register all function and type declarations so bodies can
    // reference anything declared later in the file.
    for (auto* node : prog->decls) {
        if (auto* d = dynamic_cast<struct_decl*>(node))  { visit_struct_decl(d, ctx);  continue; }
        if (auto* d = dynamic_cast<union_decl*>(node))   { visit_union_decl(d, ctx);   continue; }
        if (auto* d = dynamic_cast<enum_decl*>(node))    { visit_enum_decl(d, ctx);    continue; }
        if (auto* d = dynamic_cast<typedef_decl*>(node)) { visit_typedef_decl(d, ctx); continue; }
        if (auto* d = dynamic_cast<func_decl*>(node))    { visit_func_decl_prototype(d, ctx); continue; }
        // Global var declarations are deferred to pass 2 (may reference types defined above).
    }

    // Pass 2: emit global variables and function bodies.
    for (auto* node : prog->decls) {
        if (auto* d = dynamic_cast<var_decl*>(node))  { visit_global_var_decl(d, ctx); continue; }
        if (auto* d = dynamic_cast<func_decl*>(node)) { visit_func_decl(d, ctx);       continue; }
        // Type declarations were already handled in pass 1.
    }
}
