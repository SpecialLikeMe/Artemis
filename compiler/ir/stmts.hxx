#pragma once
#include "exprs.hxx"
#include "asm.hxx"

// Forward declare the statement dispatcher for recursive call sites (e.g. if body calls visit_stmt).
inline void visit_stmt(ast_node* node, ir_context* ctx);

// ------------------------------------------------------------------ block

inline void visit_block_stmt(block_stmt* blk, ir_context* ctx) {
    ctx->push_scope();
    for (auto* s : blk->stmts) {
        if (ctx->is_terminated()) break; // dead code after a terminator
        visit_stmt(s, ctx);
    }
    ctx->pop_scope();
}

// ------------------------------------------------------------------ local variable declaration

inline void visit_local_var_decl(var_decl* d, ir_context* ctx) {
    LLVMTypeRef alloca_t = llvm_type_of(d->type, ctx);

    // For arrays, store element type; for scalars/pointers, store the type as-is.
    LLVMTypeRef elem_t = alloca_t;
    if (LLVMGetTypeKind(alloca_t) == LLVMArrayTypeKind)
        elem_t = LLVMGetElementType(alloca_t);

    // For pointer vars, track the pointed-to type so *p can load correctly.
    LLVMTypeRef deref_t = nullptr;
    if (d->type->pointer_depth > 0) {
        type_node stripped = *d->type;
        stripped.pointer_depth--;
        deref_t = llvm_type_of(&stripped, ctx);
    }

    LLVMValueRef alloca = LLVMBuildAlloca(ctx->llvm_builder, alloca_t, d->name.c_str());
    ctx->declare_local(d->name, alloca, elem_t, deref_t);

    if (d->init.has_value()) {
        LLVMValueRef init_val = visit_expr(d->init.value(), ctx);
        init_val = coerce_int_val(init_val, alloca_t, ctx->llvm_builder);
        LLVMBuildStore(ctx->llvm_builder, init_val, alloca);
    } else {
        LLVMBuildStore(ctx->llvm_builder, LLVMConstNull(alloca_t), alloca);
    }
}

// ------------------------------------------------------------------ expression statement

inline void visit_expr_stmt(expr_stmt* s, ir_context* ctx) {
    visit_expr(s->expr, ctx);
}

// ------------------------------------------------------------------ if / else

inline void visit_if_stmt(if_stmt* s, ir_context* ctx) {
    LLVMValueRef cond_val = visit_expr(s->cond, ctx);

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
    LLVMValueRef      subject = visit_expr(s->subject, ctx);
    LLVMValueRef      fn      = ctx->current_func;
    LLVMBasicBlockRef exit_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "switch_exit");

    // Locate the default case (if any) to use as the otherwise target.
    LLVMBasicBlockRef default_bb = exit_bb;
    for (auto& [label, blk] : s->cases) {
        if (!label.has_value()) {
            default_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "switch_default");
            break;
        }
    }

    LLVMValueRef sw = LLVMBuildSwitch(ctx->llvm_builder, subject, default_bb,
                                       static_cast<unsigned>(s->cases.size()));

    ctx->push_loop(exit_bb, nullptr); // break targets exit_bb; continue not valid in switch

    for (auto& [label, blk] : s->cases) {
        LLVMBasicBlockRef case_bb;
        if (label.has_value()) {
            case_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "switch_case");
            LLVMValueRef case_val = visit_expr(label.value(), ctx);
            LLVMAddCase(sw, case_val, case_bb);
        } else {
            case_bb = default_bb;
        }
        LLVMPositionBuilderAtEnd(ctx->llvm_builder, case_bb);
        visit_block_stmt(blk, ctx);
        if (!ctx->is_terminated()) LLVMBuildBr(ctx->llvm_builder, exit_bb); // implicit fallthrough prevention
    }

    ctx->pop_loop();
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, exit_bb);
}

// ------------------------------------------------------------------ return

inline void visit_return_stmt(return_stmt* s, ir_context* ctx) {
    if (!s->value.has_value()) {
        LLVMBuildRetVoid(ctx->llvm_builder);
        return;
    }
    LLVMValueRef val = visit_expr(s->value.value(), ctx);
    LLVMBuildRet(ctx->llvm_builder, val);
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
    if (auto* n = dynamic_cast<switch_stmt*>(node))   { visit_switch_stmt(n, ctx);  return; }
    if (auto* n = dynamic_cast<return_stmt*>(node))   { visit_return_stmt(n, ctx);  return; }
    if (auto* n = dynamic_cast<break_stmt*>(node))    { visit_break_stmt(n, ctx);   return; }
    if (auto* n = dynamic_cast<continue_stmt*>(node)) { visit_continue_stmt(n, ctx); return; }
    if (auto* n = dynamic_cast<var_decl*>(node))      { visit_local_var_decl(n, ctx); return; }
    if (auto* n = dynamic_cast<expr_stmt*>(node))     { visit_expr_stmt(n, ctx);    return; }
    if (auto* n = dynamic_cast<asm_stmt*>(node))      { visit_asm_stmt(n, ctx);     return; }

    throw std::runtime_error("IR: Unknown statement kind in visit_stmt");
}
