#pragma once
#include "exprs.hxx"
#include "asm.hxx"

// Forward declare the statement dispatcher for recursive call sites (e.g. if body calls visit_stmt).
inline void visit_stmt(ast_node* node, ir_context* ctx);
// Forward declare expr visitor for defer emission
inline LLVMValueRef visit_expr(expr_node* e, ir_context* ctx);
// Forward declare block visitor used by emit_deferred
inline void visit_block_stmt(block_stmt* blk, ir_context* ctx);
// Forward declare generic-class instantiation trigger (defined in decls.hxx).
inline void maybe_instantiate_generic_type(const type_node* t, ir_context* ctx);

// Emit deferred items in reverse order (LIFO).
inline void emit_deferred(const std::vector<std::pair<void*, bool>>& items, ir_context* ctx) {
    for (auto it = items.rbegin(); it != items.rend(); ++it) {
        if (ctx->is_terminated()) break;
        if (it->second) {
            // block
            visit_block_stmt(static_cast<block_stmt*>(it->first), ctx);
        } else {
            // expr
            visit_expr(static_cast<expr_node*>(it->first), ctx);
        }
    }
}

// ------------------------------------------------------------------ block

inline void visit_block_stmt(block_stmt* blk, ir_context* ctx) {
    ctx->push_scope();
    ctx->push_defer_scope();
    for (auto* s : blk->stmts) {
        if (ctx->is_terminated()) break; // dead code after a terminator
        visit_stmt(s, ctx);
    }
    // Emit deferred items at end of block (fall-through path)
    auto deferred = ctx->pop_defer_scope();
    if (!ctx->is_terminated()) emit_deferred(deferred, ctx);
    ctx->pop_scope();
}

// ------------------------------------------------------------------ local variable declaration

inline void visit_local_var_decl(var_decl* d, ir_context* ctx) {
    maybe_instantiate_generic_type(d->type, ctx); // monomorphize generic class on first use
    LLVMTypeRef alloca_t = llvm_type_of(d->type, ctx);

    // For arrays, store element type; for scalars/pointers, store the type as-is.
    LLVMTypeRef elem_t = alloca_t;
    if (LLVMGetTypeKind(alloca_t) == LLVMArrayTypeKind)
        elem_t = LLVMGetElementType(alloca_t);

    // For pointer vars, track the pointed-to type so *p can load correctly.
    // Check is_func_ptr first: parser sets pointer_depth=1 on func-ptr types, so the
    // pointer_depth branch would give a wrong deref type (another pointer, not the function type).
    LLVMTypeRef deref_t = nullptr;
    if (d->type->is_func_ptr && d->type->fp_ret) {
        LLVMTypeRef ret_t = llvm_type_of(d->type->fp_ret, ctx);
        std::vector<LLVMTypeRef> param_ts;
        for (auto* pt : d->type->fp_params) param_ts.push_back(llvm_type_of(pt, ctx));
        deref_t = LLVMFunctionType(ret_t, param_ts.data(),
                                   static_cast<unsigned>(param_ts.size()),
                                   d->type->fp_variadic ? 1 : 0);
    } else {
        // Resolve typedef aliases so `typedef i32* IntPtr; IntPtr p; *p` tracks i32.
        type_node resolved = ir_resolve_alias_node(d->type, ctx);
        if (resolved.pointer_depth > 0) {
            resolved.pointer_depth--;
            deref_t = llvm_type_of(&resolved, ctx);
        }
    }

    LLVMValueRef alloca = LLVMBuildAlloca(ctx->llvm_builder, alloca_t, d->name.c_str());
    ctx->declare_local(d->name, alloca, elem_t, deref_t, is_unsigned_type_node(d->type));

    // Named-field class initializer:  Type v = Type { .f = x };  or  Type v = .{ .f = x };
    if (d->init.has_value() && d->init.value()->kind == expr_kind::class_init
        && LLVMGetTypeKind(alloca_t) == LLVMStructTypeKind) {
        std::string tname = LLVMGetStructName(alloca_t) ? LLVMGetStructName(alloca_t) : "";
        emit_class_init_into(d->init.value(), alloca, alloca_t, tname, ctx);
        return;
    }

    if (d->init.has_value()) {
        LLVMValueRef init_val = visit_expr(d->init.value(), ctx);
        init_val = coerce_int_val(init_val, alloca_t, ctx->llvm_builder);
        LLVMBuildStore(ctx->llvm_builder, init_val, alloca);
    } else {
        LLVMBuildStore(ctx->llvm_builder, LLVMConstNull(alloca_t), alloca);
    }

    // Implicit constructor invocation for class types.
    // Skipped for consteval vars — the user calls __construct__ explicitly.
    if (!d->is_consteval &&
        d->type && !d->type->is_primitive && d->type->name && d->type->pointer_depth == 0
        && LLVMGetTypeKind(alloca_t) == LLVMStructTypeKind) {
        // Locate ClassName__MT___construct__ walking the inheritance chain.
        // Use the resolved LLVM struct name (handles generic instantiations).
        std::string search = LLVMGetStructName(alloca_t)
                             ? LLVMGetStructName(alloca_t) : *d->type->name;
        LLVMValueRef ctor_fn = nullptr;
        LLVMTypeRef  ctor_ft = nullptr;
        while (!search.empty()) {
            std::string cn = search + "__MT___construct__";
            auto cit = ctx->global_funcs.find(cn);
            if (cit != ctx->global_funcs.end()) {
                ctor_fn = cit->second;
                ctor_ft = ctx->global_func_types[cn];
                break;
            }
            auto ci = ctx->class_infos.find(search);
            search = (ci != ctx->class_infos.end()) ? ci->second.base_name : "";
        }
        if (ctor_fn) {
            unsigned nparams = LLVMCountParamTypes(ctor_ft);
            bool explicit_call = d->has_ctor_parens || !d->ctor_args.empty();
            // Auto-call only a no-arg (self-only) constructor when no explicit (...) given.
            if (explicit_call || nparams == 1) {
                std::vector<LLVMValueRef> cargs = { alloca };
                std::vector<LLVMTypeRef> pts(nparams);
                LLVMGetParamTypes(ctor_ft, pts.data());
                for (size_t i = 0; i < d->ctor_args.size(); ++i) {
                    LLVMValueRef av = visit_expr(d->ctor_args[i], ctx);
                    if (i + 1 < nparams) av = coerce_int_val(av, pts[i + 1], ctx->llvm_builder);
                    cargs.push_back(av);
                }
                LLVMBuildCall2(ctx->llvm_builder, ctor_ft, ctor_fn,
                               cargs.data(), static_cast<unsigned>(cargs.size()), "");
            }
        }
    }
}

// ------------------------------------------------------------------ expression statement

inline void visit_expr_stmt(expr_stmt* s, ir_context* ctx) {
    visit_expr(s->expr, ctx);
}

// ------------------------------------------------------------------ if / else

inline void visit_if_stmt(if_stmt* s, ir_context* ctx) {
    LLVMValueRef cond_val = visit_expr(s->cond, ctx);

    // constexpr if: if the condition folds to a compile-time constant, emit only the
    // taken branch and discard the other entirely (compile-time branch elimination).
    if (s->is_constexpr && LLVMIsConstant(cond_val)
        && LLVMGetTypeKind(LLVMTypeOf(cond_val)) == LLVMIntegerTypeKind) {
        bool taken = LLVMConstIntGetZExtValue(cond_val) != 0;
        if (taken)             visit_stmt(s->then_body, ctx);
        else if (s->else_body) visit_stmt(s->else_body, ctx);
        return;
    }

    // Normalise any non-i1 condition to i1.
    if (LLVMGetTypeKind(LLVMTypeOf(cond_val)) != LLVMIntegerTypeKind ||
        LLVMGetIntTypeWidth(LLVMTypeOf(cond_val)) != 1) {
        cond_val = LLVMBuildICmp(ctx->llvm_builder, LLVMIntNE,
                                  cond_val, LLVMConstNull(LLVMTypeOf(cond_val)), "if_cond");
    }

    LLVMValueRef      fn       = ctx->current_func;
    LLVMBasicBlockRef then_bb  = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "if_then");
    LLVMBasicBlockRef else_bb  = s->else_body
        ? LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "if_else")
        : nullptr;
    LLVMBasicBlockRef merge_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "if_merge");

    LLVMBuildCondBr(ctx->llvm_builder, cond_val, then_bb, else_bb ? else_bb : merge_bb);

    // Emit then branch.
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, then_bb);
    visit_stmt(s->then_body, ctx);
    if (!ctx->is_terminated()) LLVMBuildBr(ctx->llvm_builder, merge_bb);

    // Emit else branch (optional).
    if (else_bb) {
        LLVMPositionBuilderAtEnd(ctx->llvm_builder, else_bb);
        visit_stmt(s->else_body, ctx);
        if (!ctx->is_terminated()) LLVMBuildBr(ctx->llvm_builder, merge_bb);
    }

    LLVMPositionBuilderAtEnd(ctx->llvm_builder, merge_bb);
}

// ------------------------------------------------------------------ while

inline void visit_while_stmt(while_stmt* s, ir_context* ctx) {
    LLVMValueRef      fn       = ctx->current_func;
    LLVMBasicBlockRef cond_bb  = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "while_cond");
    LLVMBasicBlockRef body_bb  = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "while_body");
    LLVMBasicBlockRef exit_bb  = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "while_exit");

    LLVMBuildBr(ctx->llvm_builder, cond_bb);

    // Condition block.
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, cond_bb);
    LLVMValueRef cond_val = visit_expr(s->cond, ctx);
    if (LLVMGetIntTypeWidth(LLVMTypeOf(cond_val)) != 1)
        cond_val = LLVMBuildICmp(ctx->llvm_builder, LLVMIntNE,
                                  cond_val, LLVMConstNull(LLVMTypeOf(cond_val)), "while_cond_i1");
    LLVMBuildCondBr(ctx->llvm_builder, cond_val, body_bb, exit_bb);

    // Body block.
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, body_bb);
    ctx->push_loop(exit_bb, cond_bb);
    visit_stmt(s->body, ctx);
    ctx->pop_loop();
    if (!ctx->is_terminated()) LLVMBuildBr(ctx->llvm_builder, cond_bb);

    LLVMPositionBuilderAtEnd(ctx->llvm_builder, exit_bb);
}

// ------------------------------------------------------------------ for

// Range-based for: for (T elem : expr) body
// Supports static arrays (expr has array_size) and pointer+count iteration.
inline void visit_for_range_stmt(for_range_stmt* s, ir_context* ctx) {
    LLVMValueRef      fn      = ctx->current_func;
    LLVMBasicBlockRef cond_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "range_cond");
    LLVMBasicBlockRef body_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "range_body");
    LLVMBasicBlockRef step_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "range_step");
    LLVMBasicBlockRef exit_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "range_exit");

    // Evaluate the range expression to get the base pointer/array.
    LLVMValueRef range_val = visit_expr(s->range, ctx);

    // Determine element type and count.
    LLVMTypeRef elem_llvm_t = s->var_type ? llvm_type_of(s->var_type, ctx) : LLVMInt8TypeInContext(ctx->llvm_ctx);

    // Try to get count from the array type's size expression.
    LLVMValueRef count_val = nullptr;
    if (s->range && s->range->cast_type && s->range->cast_type->array_size.has_value()) {
        count_val = visit_expr(s->range->cast_type->array_size.value(), ctx);
    }
    if (!count_val) {
        // No count available — zero-iteration loop (safe fallback).
        count_val = LLVMConstInt(LLVMInt64TypeInContext(ctx->llvm_ctx), 0, 0);
    }
    count_val = LLVMBuildIntCast2(ctx->llvm_builder, count_val, LLVMInt64TypeInContext(ctx->llvm_ctx), 0, "range_count");

    // Allocate the index variable.
    LLVMValueRef idx_alloca = LLVMBuildAlloca(ctx->llvm_builder, LLVMInt64TypeInContext(ctx->llvm_ctx), "range_idx");
    LLVMBuildStore(ctx->llvm_builder, LLVMConstInt(LLVMInt64TypeInContext(ctx->llvm_ctx), 0, 0), idx_alloca);

    // Allocate the element variable that the body uses.
    LLVMValueRef elem_alloca = LLVMBuildAlloca(ctx->llvm_builder, elem_llvm_t, s->var_name.c_str());

    LLVMBuildBr(ctx->llvm_builder, cond_bb);

    // Condition: idx < count
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, cond_bb);
    LLVMValueRef idx_cur = LLVMBuildLoad2(ctx->llvm_builder, LLVMInt64TypeInContext(ctx->llvm_ctx), idx_alloca, "idx");
    LLVMValueRef cond_v  = LLVMBuildICmp(ctx->llvm_builder, LLVMIntULT, idx_cur, count_val, "range_lt");
    LLVMBuildCondBr(ctx->llvm_builder, cond_v, body_bb, exit_bb);

    // Body: load arr[idx] into elem, then run body.
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, body_bb);
    ctx->push_scope();
    // GEP: ptr to arr[idx]
    LLVMValueRef zero = LLVMConstInt(LLVMInt64TypeInContext(ctx->llvm_ctx), 0, 0);
    LLVMValueRef indices[2] = { zero, idx_cur };
    LLVMValueRef elem_ptr;
    // If range_val is a pointer to array, use 2-index GEP; if pointer to element, use 1-index.
    LLVMTypeRef rv_type = LLVMTypeOf(range_val);
    (void)rv_type;
    elem_ptr = LLVMBuildGEP2(ctx->llvm_builder, elem_llvm_t, range_val, &idx_cur, 1, "elem_ptr");
    LLVMValueRef elem_val = LLVMBuildLoad2(ctx->llvm_builder, elem_llvm_t, elem_ptr, "elem");
    LLVMBuildStore(ctx->llvm_builder, elem_val, elem_alloca);

    // Declare loop variable in scope.
    ctx->declare_local(s->var_name, elem_alloca, elem_llvm_t, nullptr, false);

    ctx->push_loop(exit_bb, step_bb);
    visit_stmt(s->body, ctx);
    ctx->pop_loop();
    if (!ctx->is_terminated()) LLVMBuildBr(ctx->llvm_builder, step_bb);
    ctx->pop_scope();

    // Step: idx++
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, step_bb);
    LLVMValueRef idx_new = LLVMBuildAdd(ctx->llvm_builder, idx_cur, LLVMConstInt(LLVMInt64TypeInContext(ctx->llvm_ctx), 1, 0), "idx_inc");
    LLVMBuildStore(ctx->llvm_builder, idx_new, idx_alloca);
    LLVMBuildBr(ctx->llvm_builder, cond_bb);

    LLVMPositionBuilderAtEnd(ctx->llvm_builder, exit_bb);
}

inline void visit_for_stmt(for_stmt* s, ir_context* ctx) {
    LLVMValueRef      fn      = ctx->current_func;
    LLVMBasicBlockRef cond_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "for_cond");
    LLVMBasicBlockRef body_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "for_body");
    LLVMBasicBlockRef step_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "for_step");
    LLVMBasicBlockRef exit_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "for_exit");

    // Init (runs in the current scope, which we extend for the for-init scope).
    ctx->push_scope();
    if (s->init) visit_stmt(s->init, ctx);

    LLVMBuildBr(ctx->llvm_builder, cond_bb);

    // Condition block.
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, cond_bb);
    if (s->cond) {
        LLVMValueRef cv = visit_expr(s->cond, ctx);
        if (LLVMGetIntTypeWidth(LLVMTypeOf(cv)) != 1)
            cv = LLVMBuildICmp(ctx->llvm_builder, LLVMIntNE,
                               cv, LLVMConstNull(LLVMTypeOf(cv)), "for_cond_i1");
        LLVMBuildCondBr(ctx->llvm_builder, cv, body_bb, exit_bb);
    } else {
        LLVMBuildBr(ctx->llvm_builder, body_bb); // infinite loop if no condition
    }

    // Body block.
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, body_bb);
    ctx->push_loop(exit_bb, step_bb);
    visit_stmt(s->body, ctx);
    ctx->pop_loop();
    if (!ctx->is_terminated()) LLVMBuildBr(ctx->llvm_builder, step_bb);

    // Step block.
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, step_bb);
    if (s->step) visit_expr(s->step, ctx);
    if (!ctx->is_terminated()) LLVMBuildBr(ctx->llvm_builder, cond_bb);

    LLVMPositionBuilderAtEnd(ctx->llvm_builder, exit_bb);
    ctx->pop_scope(); // end for-init scope
}

// ------------------------------------------------------------------ switch

inline void visit_switch_stmt(switch_stmt* s, ir_context* ctx) {
    LLVMValueRef      fn      = ctx->current_func;
    LLVMBasicBlockRef exit_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "switch_exit");

    // Evaluate case labels and build case blocks BEFORE emitting the switch instruction.
    // This avoids inserting load instructions after the switch terminator.
    struct case_info {
        std::optional<LLVMValueRef> val; // nullopt = default
        LLVMBasicBlockRef           bb;
        block_stmt*                 blk;
    };
    std::vector<case_info> cases;
    LLVMBasicBlockRef default_bb = exit_bb;

    for (auto& [label, blk] : s->cases) {
        if (label.has_value()) {
            LLVMValueRef case_val = visit_expr(label.value(), ctx);
            LLVMBasicBlockRef bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "switch_case");
            cases.push_back({case_val, bb, blk});
        } else {
            LLVMBasicBlockRef bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "switch_default");
            default_bb = bb;
            cases.push_back({std::nullopt, bb, blk});
        }
    }

    LLVMValueRef subject = visit_expr(s->subject, ctx);
    LLVMValueRef sw = LLVMBuildSwitch(ctx->llvm_builder, subject, default_bb,
                                       static_cast<unsigned>(cases.size()));
    for (auto& c : cases)
        if (c.val.has_value())
            LLVMAddCase(sw, c.val.value(), c.bb);

    ctx->push_loop(exit_bb, nullptr); // break targets exit_bb; continue not valid in switch

    for (size_t i = 0; i < cases.size(); i++) {
        LLVMPositionBuilderAtEnd(ctx->llvm_builder, cases[i].bb);
        visit_block_stmt(cases[i].blk, ctx);
        if (!ctx->is_terminated()) {
            // Fallthrough: branch to next case body; last case falls to exit.
            LLVMBasicBlockRef next = (i + 1 < cases.size()) ? cases[i + 1].bb : exit_bb;
            LLVMBuildBr(ctx->llvm_builder, next);
        }
    }

    ctx->pop_loop();
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, exit_bb);
}

// ------------------------------------------------------------------ defer

inline void visit_defer_stmt(defer_stmt* s, ir_context* ctx) {
    // Register the deferred item in the current defer scope; it will be emitted on exit.
    if (s->blk)  ctx->add_defer(static_cast<void*>(s->blk),  true);
    else if (s->expr) ctx->add_defer(static_cast<void*>(s->expr), false);
}

// ------------------------------------------------------------------ return

inline void visit_return_stmt(return_stmt* s, ir_context* ctx) {
    // Emit ALL deferred items (all scopes) before returning
    // We collect from the top of the defer stack inward
    std::vector<std::vector<std::pair<void*, bool>>> all_deferred;
    for (auto& scope_items : ctx->defer_stack)
        all_deferred.push_back(scope_items);
    for (auto it = all_deferred.rbegin(); it != all_deferred.rend(); ++it)
        emit_deferred(*it, ctx);

    if (!s->value.has_value()) {
        LLVMBuildRetVoid(ctx->llvm_builder);
        return;
    }
    LLVMValueRef val = visit_expr(s->value.value(), ctx);
    // Coerce value to the function's declared return type (e.g. i8 -> i32 implicit widening).
    LLVMTypeRef fn_t  = LLVMGlobalGetValueType(ctx->current_func);
    LLVMTypeRef ret_t = LLVMGetReturnType(fn_t);
    // Integer → pointer: inttoptr (handles "return 0" as null pointer constant).
    if (LLVMGetTypeKind(ret_t) == LLVMPointerTypeKind &&
        LLVMGetTypeKind(LLVMTypeOf(val)) == LLVMIntegerTypeKind)
        val = LLVMBuildIntToPtr(ctx->llvm_builder, val, ret_t, "nullcast");
    else
        val = coerce_int_val(val, ret_t, ctx->llvm_builder);
    LLVMBuildRet(ctx->llvm_builder, val);
}

// ------------------------------------------------------------------ throw / try-except

// Returns (or creates) the module-level exception state globals.
struct exc_globals {
    LLVMValueRef val;       // @__arc_exc_val  — i64, stores the thrown value
    LLVMValueRef jbuf_ptr;  // @__arc_exc_jbuf — i8*, points at current jmp_buf alloca
};

inline exc_globals get_exc_globals(ir_context* ctx) {
    LLVMTypeRef i64t  = LLVMInt64TypeInContext(ctx->llvm_ctx);
    LLVMTypeRef i8pt  = LLVMPointerType(LLVMInt8TypeInContext(ctx->llvm_ctx), 0);

    auto get_or_create = [&](const char* name, LLVMTypeRef ty) -> LLVMValueRef {
        LLVMValueRef g = LLVMGetNamedGlobal(ctx->llvm_mod, name);
        if (!g) {
            g = LLVMAddGlobal(ctx->llvm_mod, ty, name);
            LLVMSetInitializer(g, LLVMConstNull(ty));
            LLVMSetLinkage(g, LLVMInternalLinkage);
        }
        return g;
    };

    return { get_or_create("__arc_exc_val",  i64t),
             get_or_create("__arc_exc_jbuf", i8pt) };
}

// Declare setjmp / longjmp as extern C.
// On Windows x64 (MinGW), the ABI requires _setjmp(jbuf, frame_ptr) — two args.
// On POSIX, setjmp(jbuf) takes one arg.
#ifdef _WIN32
static constexpr bool ARC_WIN_SETJMP = true;
#else
static constexpr bool ARC_WIN_SETJMP = false;
#endif

inline LLVMValueRef get_setjmp_fn(ir_context* ctx) {
    const char* fname = ARC_WIN_SETJMP ? "_setjmp" : "setjmp";
    LLVMValueRef fn = LLVMGetNamedFunction(ctx->llvm_mod, fname);
    if (!fn) {
        LLVMTypeRef i8pt = LLVMPointerType(LLVMInt8TypeInContext(ctx->llvm_ctx), 0);
        LLVMTypeRef i32t = LLVMInt32TypeInContext(ctx->llvm_ctx);
        LLVMTypeRef params[2] = { i8pt, i8pt };
        unsigned nparams = ARC_WIN_SETJMP ? 2u : 1u;
        LLVMTypeRef fty = LLVMFunctionType(i32t, params, nparams, 0);
        fn = LLVMAddFunction(ctx->llvm_mod, fname, fty);
        {
            unsigned k = LLVMGetEnumAttributeKindForName("returns_twice", 13);
            if (k) LLVMAddAttributeAtIndex(fn, LLVMAttributeFunctionIndex,
                       LLVMCreateEnumAttribute(ctx->llvm_ctx, k, 0));
        }
    }
    return fn;
}

inline LLVMValueRef get_longjmp_fn(ir_context* ctx) {
    LLVMValueRef fn = LLVMGetNamedFunction(ctx->llvm_mod, "longjmp");
    if (!fn) {
        LLVMTypeRef i8pt  = LLVMPointerType(LLVMInt8TypeInContext(ctx->llvm_ctx), 0);
        LLVMTypeRef i32t  = LLVMInt32TypeInContext(ctx->llvm_ctx);
        LLVMTypeRef voidt = LLVMVoidTypeInContext(ctx->llvm_ctx);
        LLVMTypeRef params[2] = { i8pt, i32t };
        LLVMTypeRef fty = LLVMFunctionType(voidt, params, 2, 0);
        fn = LLVMAddFunction(ctx->llvm_mod, "longjmp", fty);
        {
            unsigned k = LLVMGetEnumAttributeKindForName("noreturn", 8);
            if (k) LLVMAddAttributeAtIndex(fn, LLVMAttributeFunctionIndex,
                       LLVMCreateEnumAttribute(ctx->llvm_ctx, k, 0));
        }
    }
    return fn;
}

inline void visit_throw_stmt(throw_stmt* n, ir_context* ctx) {
    // Store exception value (cast to i64) in @__arc_exc_val, then longjmp.
    auto [exc_val_g, exc_jbuf_g] = get_exc_globals(ctx);
    LLVMTypeRef i8t  = LLVMInt8TypeInContext(ctx->llvm_ctx);
    LLVMTypeRef i8pt = LLVMPointerType(i8t, 0);
    LLVMTypeRef i32t = LLVMInt32TypeInContext(ctx->llvm_ctx);
    LLVMTypeRef i64t = LLVMInt64TypeInContext(ctx->llvm_ctx);

    LLVMValueRef val = n->value ? visit_expr(n->value, ctx)
                                : LLVMConstInt(i64t, 0, 0);
    LLVMTypeRef vt = LLVMTypeOf(val);
    if (vt != i64t) {
        if (LLVMGetTypeKind(vt) == LLVMIntegerTypeKind)
            val = LLVMBuildIntCast2(ctx->llvm_builder, val, i64t, 1, "exc_cast");
        else if (LLVMGetTypeKind(vt) == LLVMPointerTypeKind)
            val = LLVMBuildPtrToInt(ctx->llvm_builder, val, i64t, "exc_cast");
        else
            val = LLVMConstInt(i64t, 0, 0);
    }
    LLVMBuildStore(ctx->llvm_builder, val, exc_val_g);

    LLVMValueRef jbuf = LLVMBuildLoad2(ctx->llvm_builder, i8pt, exc_jbuf_g, "jbuf");
    LLVMValueRef one  = LLVMConstInt(i32t, 1, 0);
    LLVMValueRef args[2] = { jbuf, one };
    LLVMTypeRef  ljparams[2] = { i8pt, i32t };
    LLVMTypeRef  ljfty = LLVMFunctionType(LLVMVoidTypeInContext(ctx->llvm_ctx), ljparams, 2, 0);
    LLVMBuildCall2(ctx->llvm_builder, ljfty, get_longjmp_fn(ctx), args, 2, "");
    LLVMBuildUnreachable(ctx->llvm_builder);
}

inline void visit_try_stmt(try_stmt* n, ir_context* ctx) {
    LLVMTypeRef i8t   = LLVMInt8TypeInContext(ctx->llvm_ctx);
    LLVMTypeRef i8pt  = LLVMPointerType(i8t, 0);
    LLVMTypeRef i32t  = LLVMInt32TypeInContext(ctx->llvm_ctx);
    LLVMTypeRef i64t  = LLVMInt64TypeInContext(ctx->llvm_ctx);
    LLVMValueRef fn   = LLVMGetBasicBlockParent(LLVMGetInsertBlock(ctx->llvm_builder));

    auto [exc_val_g, exc_jbuf_g] = get_exc_globals(ctx);

    // Alloca a jmp_buf (256 bytes, 16-byte aligned).
    LLVMTypeRef jbuf_t = LLVMArrayType(i8t, 256);
    LLVMValueRef jbuf  = LLVMBuildAlloca(ctx->llvm_builder, jbuf_t, "jbuf");
    LLVMSetAlignment(jbuf, 16);

    // Decay array to i8* pointer.
    LLVMValueRef zero  = LLVMConstInt(i32t, 0, 0);
    LLVMValueRef idxs[2] = { zero, zero };
    LLVMValueRef jbuf_i8 = LLVMBuildGEP2(ctx->llvm_builder, jbuf_t, jbuf, idxs, 2, "jbuf_i8");

    // Save old jmp_buf pointer and install ours.
    LLVMValueRef old_jbuf = LLVMBuildLoad2(ctx->llvm_builder, i8pt, exc_jbuf_g, "old_jbuf");
    LLVMBuildStore(ctx->llvm_builder, jbuf_i8, exc_jbuf_g);

    // rc = setjmp(jbuf_i8)   [Windows: _setjmp(jbuf, NULL)]
    LLVMValueRef setjmp_fn = get_setjmp_fn(ctx);
    LLVMValueRef rc;
    if constexpr (ARC_WIN_SETJMP) {
        LLVMValueRef null_ptr  = LLVMConstNull(i8pt);
        LLVMTypeRef  params2[2] = { i8pt, i8pt };
        LLVMTypeRef  sjfty = LLVMFunctionType(i32t, params2, 2, 0);
        LLVMValueRef args2[2] = { jbuf_i8, null_ptr };
        rc = LLVMBuildCall2(ctx->llvm_builder, sjfty, setjmp_fn, args2, 2, "sjrc");
    } else {
        LLVMTypeRef  sjfty = LLVMFunctionType(i32t, &i8pt, 1, 0);
        rc = LLVMBuildCall2(ctx->llvm_builder, sjfty, setjmp_fn, &jbuf_i8, 1, "sjrc");
    }

    // Branch: rc != 0 → except_bb, else → try_bb
    LLVMValueRef thrown = LLVMBuildICmp(ctx->llvm_builder, LLVMIntNE,
                                        rc, LLVMConstInt(i32t, 0, 0), "thrown");
    LLVMBasicBlockRef try_bb    = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "try");
    LLVMBasicBlockRef except_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "except");
    LLVMBasicBlockRef after_bb  = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "after_try");
    LLVMBuildCondBr(ctx->llvm_builder, thrown, except_bb, try_bb);

    // --- try body ---
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, try_bb);
    visit_block_stmt(n->body, ctx);
    if (!ctx->is_terminated()) {
        LLVMBuildStore(ctx->llvm_builder, old_jbuf, exc_jbuf_g); // restore on normal exit
        LLVMBuildBr(ctx->llvm_builder, after_bb);
    }

    // --- except handler ---
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, except_bb);
    LLVMBuildStore(ctx->llvm_builder, old_jbuf, exc_jbuf_g); // restore on exception exit
    // Declare exception variable in a new scope.
    ctx->push_scope();
    if (n->exc_type != nullptr) {
        // Named exception: except (type name) — alloca and store the exception value.
        LLVMTypeRef exc_t    = llvm_type_of(n->exc_type, ctx);
        LLVMValueRef exc_var = LLVMBuildAlloca(ctx->llvm_builder, exc_t, n->exc_name.c_str());
        // Load stored exception value and cast to the declared type.
        LLVMValueRef exc_val = LLVMBuildLoad2(ctx->llvm_builder, i64t, exc_val_g, "exc_val");
        LLVMValueRef casted;
        if (exc_t == i64t) {
            casted = exc_val;
        } else if (LLVMGetTypeKind(exc_t) == LLVMIntegerTypeKind) {
            casted = LLVMBuildIntCast2(ctx->llvm_builder, exc_val, exc_t, 1, "exc_narrow");
        } else if (LLVMGetTypeKind(exc_t) == LLVMPointerTypeKind) {
            casted = LLVMBuildIntToPtr(ctx->llvm_builder, exc_val, exc_t, "exc_ptr");
        } else {
            casted = LLVMConstNull(exc_t);
        }
        LLVMBuildStore(ctx->llvm_builder, casted, exc_var);
        ctx->declare_local(n->exc_name, exc_var, exc_t);
    }
    // else: catch-all except (...) — no exception variable, just run handler.
    visit_block_stmt(n->handler, ctx);
    ctx->pop_scope();
    if (!ctx->is_terminated())
        LLVMBuildBr(ctx->llvm_builder, after_bb);

    LLVMPositionBuilderAtEnd(ctx->llvm_builder, after_bb);
}

// ------------------------------------------------------------------ break / continue

inline void visit_break_stmt(break_stmt* /*s*/, ir_context* ctx) {
    LLVMBasicBlockRef target = ctx->current_break_target();
    if (!target)
        throw std::runtime_error("IR: 'break' with no enclosing loop or switch");
    LLVMBuildBr(ctx->llvm_builder, target);
}

inline void visit_continue_stmt(continue_stmt* /*s*/, ir_context* ctx) {
    LLVMBasicBlockRef target = ctx->current_continue_target();
    if (!target)
        throw std::runtime_error("IR: 'continue' with no enclosing loop");
    LLVMBuildBr(ctx->llvm_builder, target);
}

// ------------------------------------------------------------------ dispatcher

inline void visit_stmt(ast_node* node, ir_context* ctx) {
    if (!node || ctx->is_terminated()) return;

    if (auto* n = dynamic_cast<block_stmt*>(node))    { visit_block_stmt(n, ctx);   return; }
    if (auto* n = dynamic_cast<if_stmt*>(node))       { visit_if_stmt(n, ctx);      return; }
    if (auto* n = dynamic_cast<while_stmt*>(node))    { visit_while_stmt(n, ctx);   return; }
    if (auto* n = dynamic_cast<for_stmt*>(node))      { visit_for_stmt(n, ctx);     return; }
    if (auto* n = dynamic_cast<for_range_stmt*>(node)){ visit_for_range_stmt(n, ctx); return; }
    if (auto* n = dynamic_cast<switch_stmt*>(node))   { visit_switch_stmt(n, ctx);  return; }
    if (auto* n = dynamic_cast<return_stmt*>(node))   { visit_return_stmt(n, ctx);  return; }
    if (auto* n = dynamic_cast<break_stmt*>(node))    { visit_break_stmt(n, ctx);   return; }
    if (auto* n = dynamic_cast<continue_stmt*>(node)) { visit_continue_stmt(n, ctx); return; }
    if (auto* n = dynamic_cast<var_decl*>(node))      { visit_local_var_decl(n, ctx); return; }
    if (auto* n = dynamic_cast<expr_stmt*>(node))     { visit_expr_stmt(n, ctx);    return; }
    if (auto* n = dynamic_cast<asm_stmt*>(node))      { visit_asm_stmt(n, ctx);     return; }
    if (auto* n = dynamic_cast<defer_stmt*>(node))    { visit_defer_stmt(n, ctx);   return; }
    if (auto* n = dynamic_cast<throw_stmt*>(node))    { visit_throw_stmt(n, ctx);   return; }
    if (auto* n = dynamic_cast<try_stmt*>(node))      { visit_try_stmt(n, ctx);     return; }

    throw std::runtime_error("IR: Unknown statement kind in visit_stmt");
}
