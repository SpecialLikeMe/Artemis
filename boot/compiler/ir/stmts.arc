// Statement IR generation for the Artemis self-hosting compiler.

namespace ir {

// Forward declarations
void visit_stmt(parser.ast_node* node, ir_context* ctx);
void visit_block_stmt(parser.block_stmt* blk, ir_context* ctx);

// Emit deferred items in reverse order (LIFO).
void emit_deferred(defer_scope* scope, ir_context* ctx) {
    if (scope == (defer_scope*)0) { return; }
    i32 i = scope.len - 1;
    while (i >= 0) {
        if (ctx_is_terminated(ctx)) { break; }
        defer_item di = scope.data[i];
        if (di.is_block) {
            visit_block_stmt((parser.block_stmt*)di.ptr, ctx);
        } else {
            visit_expr((parser.expr_node*)di.ptr, ctx);
        }
        i = i - 1;
    }
}

void visit_block_stmt(parser.block_stmt* blk, ir_context* ctx) {
    ctx_push_scope(ctx);
    ctx_push_defer_scope(ctx);
    ctx_push_errdefer_scope(ctx);

    i32 i = 0;
    while (i < blk.stmts_len) {
        if (ctx_is_terminated(ctx)) { break; }
        visit_stmt(blk.stmts[i], ctx);
        i = i + 1;
    }

    defer_scope ds = ctx_pop_defer_scope(ctx);
    ctx_pop_errdefer_scope(ctx);
    if (!ctx_is_terminated(ctx)) {
        emit_deferred(&ds, ctx);
    }
    ctx_pop_scope(ctx);
}

// ---- Local variable declaration ----

void visit_local_var_decl(parser.var_decl* d, ir_context* ctx) {
    if (d.is_sta) { return; }
    if (d.type != (parser.type_node*)0 && d.type.is_sta) { return; }

    i8* alloca_t = llvm_type_of(d.type, ctx);
    i8* elem_t   = alloca_t;
    i32 tk = LLVMGetTypeKind(alloca_t);
    if (tk == LLVMArrayTypeKind) {
        elem_t = LLVMGetElementType(alloca_t);
    }

    // Deref type for pointer variables
    i8* deref_t = (i8*)0;
    if (d.type != (parser.type_node*)0 && !d.type.is_func_ptr && d.type.pointer_depth > 0) {
        parser.type_node resolved;
        resolved = *d.type;
        resolved.pointer_depth = resolved.pointer_depth - 1;
        deref_t = llvm_type_of(&resolved, ctx);
    }

    i8* alloca = LLVMBuildAlloca(ctx.llvm_builder, alloca_t, d.name);
    bool is_uns = is_unsigned_type_node(d.type);
    // For arrays, store the full array type so subscript GEP can safely get element type.
    i8* local_t = (tk == LLVMArrayTypeKind) ? alloca_t : elem_t;
    ctx_declare_local(ctx, d.name, alloca, local_t, deref_t, is_uns);

    if (d.has_init) {
        i8* init_val = visit_expr(d.init, ctx);
        if (init_val != (i8*)0) {
            init_val = coerce_int_val(init_val, alloca_t, ctx.llvm_builder);
            LLVMBuildStore(ctx.llvm_builder, init_val, alloca);
        } else {
            LLVMBuildStore(ctx.llvm_builder, LLVMConstNull(alloca_t), alloca);
        }
    } else {
        LLVMBuildStore(ctx.llvm_builder, LLVMConstNull(alloca_t), alloca);
    }
}

// ---- if/else ----

void visit_if_stmt(parser.if_stmt* s, ir_context* ctx) {
    i8* cond_val     = visit_expr(s.cond, ctx);
    i8* raw_cond_val = cond_val;
    if (cond_val == (i8*)0) { return; }

    // Normalize to i1
    i8* cond_t = LLVMTypeOf(cond_val);
    i32 ck = LLVMGetTypeKind(cond_t);
    bool need_norm = false;
    if (ck == LLVMIntegerTypeKind) {
        if (LLVMGetIntTypeWidth(cond_t) != 1) { need_norm = true; }
    } else {
        need_norm = true;
    }
    if (need_norm) {
        cond_val = LLVMBuildICmp(ctx.llvm_builder, LLVMIntNE,
                                       cond_val, LLVMConstNull(cond_t), "if_cond");
    }

    i8* fn       = ctx.current_func;
    i8* then_bb  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "if_then");
    i8* else_bb_ptr = (i8*)0;
    if (s.else_body != (parser.ast_node*)0) {
        else_bb_ptr = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "if_else");
    }
    i8* merge_bb = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "if_merge");

    i8* false_dst = else_bb_ptr != (i8*)0 ? else_bb_ptr : merge_bb;
    LLVMBuildCondBr(ctx.llvm_builder, cond_val, then_bb, false_dst);

    // Then branch
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, then_bb);
    ctx_push_scope(ctx);
    if (s.then_capture != (i8*)0) {
        i8* raw_t = LLVMTypeOf(raw_cond_val);
        i8* cap   = LLVMBuildAlloca(ctx.llvm_builder, raw_t, s.then_capture);
        LLVMBuildStore(ctx.llvm_builder, raw_cond_val, cap);
        ctx_declare_local(ctx, s.then_capture, cap, raw_t, (i8*)0, false);
    }
    visit_stmt(s.then_body, ctx);
    ctx_pop_scope(ctx);
    if (!ctx_is_terminated(ctx)) {
        LLVMBuildBr(ctx.llvm_builder, merge_bb);
    }

    // Else branch (if present)
    if (else_bb_ptr != (i8*)0) {
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, else_bb_ptr);
        ctx_push_scope(ctx);
        if (s.else_capture != (i8*)0) {
            i8* raw_t = LLVMTypeOf(raw_cond_val);
            i8* cap   = LLVMBuildAlloca(ctx.llvm_builder, raw_t, s.else_capture);
            LLVMBuildStore(ctx.llvm_builder, raw_cond_val, cap);
            ctx_declare_local(ctx, s.else_capture, cap, raw_t, (i8*)0, false);
        }
        visit_stmt(s.else_body, ctx);
        ctx_pop_scope(ctx);
        if (!ctx_is_terminated(ctx)) {
            LLVMBuildBr(ctx.llvm_builder, merge_bb);
        }
    }

    LLVMPositionBuilderAtEnd(ctx.llvm_builder, merge_bb);
}

// ---- while ----

void visit_while_stmt(parser.while_stmt* s, ir_context* ctx) {
    i8* fn      = ctx.current_func;
    i8* cond_bb = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "while_cond");
    i8* body_bb = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "while_body");
    i8* exit_bb = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "while_exit");

    LLVMBuildBr(ctx.llvm_builder, cond_bb);

    LLVMPositionBuilderAtEnd(ctx.llvm_builder, cond_bb);
    i8* cond_val = visit_expr(s.cond, ctx);
    if (cond_val == (i8*)0) {
        LLVMBuildBr(ctx.llvm_builder, exit_bb);
    } else {
        i8* cond_t = LLVMTypeOf(cond_val);
        i32 cond_kind = LLVMGetTypeKind(cond_t);
        bool needs_norm_w = false;
        if (cond_kind == LLVMIntegerTypeKind) {
            if (LLVMGetIntTypeWidth(cond_t) != 1) { needs_norm_w = true; }
        } else {
            needs_norm_w = true;
        }
        if (needs_norm_w) {
            cond_val = LLVMBuildICmp(ctx.llvm_builder, LLVMIntNE,
                                           cond_val, LLVMConstNull(cond_t), "while_cond");
        }
        LLVMBuildCondBr(ctx.llvm_builder, cond_val, body_bb, exit_bb);
    }

    LLVMPositionBuilderAtEnd(ctx.llvm_builder, body_bb);
    ctx_push_loop(ctx, exit_bb, cond_bb);
    visit_stmt(s.body, ctx);
    ctx_pop_loop(ctx);
    if (!ctx_is_terminated(ctx)) {
        LLVMBuildBr(ctx.llvm_builder, cond_bb);
    }

    LLVMPositionBuilderAtEnd(ctx.llvm_builder, exit_bb);
}

// ---- for ----

void visit_for_stmt(parser.for_stmt* s, ir_context* ctx) {
    ctx_push_scope(ctx);

    // Init
    if (s.init != (parser.ast_node*)0) {
        visit_stmt(s.init, ctx);
    }

    i8* fn       = ctx.current_func;
    i8* cond_bb  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "for_cond");
    i8* body_bb  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "for_body");
    i8* step_bb  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "for_step");
    i8* exit_bb  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "for_exit");

    LLVMBuildBr(ctx.llvm_builder, cond_bb);

    // Condition
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, cond_bb);
    if (s.cond != (parser.expr_node*)0) {
        i8* cond_val = visit_expr(s.cond, ctx);
        if (cond_val != (i8*)0) {
            i8* ct = LLVMTypeOf(cond_val);
            i32 ct_kind = LLVMGetTypeKind(ct);
            bool needs_norm_f = false;
            if (ct_kind == LLVMIntegerTypeKind) {
                if (LLVMGetIntTypeWidth(ct) != 1) { needs_norm_f = true; }
            } else { needs_norm_f = true; }
            if (needs_norm_f) {
                cond_val = LLVMBuildICmp(ctx.llvm_builder, LLVMIntNE,
                                               cond_val, LLVMConstNull(ct), "for_cond");
            }
            LLVMBuildCondBr(ctx.llvm_builder, cond_val, body_bb, exit_bb);
        } else {
            LLVMBuildBr(ctx.llvm_builder, body_bb);
        }
    } else {
        LLVMBuildBr(ctx.llvm_builder, body_bb);
    }

    // Body
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, body_bb);
    ctx_push_loop(ctx, exit_bb, step_bb);
    visit_stmt(s.body, ctx);
    ctx_pop_loop(ctx);
    if (!ctx_is_terminated(ctx)) {
        LLVMBuildBr(ctx.llvm_builder, step_bb);
    }

    // Step
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, step_bb);
    if (s.step != (parser.expr_node*)0) {
        visit_expr(s.step, ctx);
    }
    LLVMBuildBr(ctx.llvm_builder, cond_bb);

    LLVMPositionBuilderAtEnd(ctx.llvm_builder, exit_bb);
    ctx_pop_scope(ctx);
}

// ---- switch ----

void visit_switch_stmt(parser.switch_stmt* s, ir_context* ctx) {
    i8* val = visit_expr(s.val, ctx);
    if (val == (i8*)0) { return; }

    i8* fn       = ctx.current_func;
    i8* exit_bb  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "sw_exit");
    i8* default_bb = exit_bb;

    // Build body blocks
    i8** body_bbs = (i8**)malloc(sizeof(i8*) * (u64)s.cases_len);
    i32 i = 0;
    while (i < s.cases_len) {
        body_bbs[i] = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "sw_case");
        if (s.case_is_default[i]) { default_bb = body_bbs[i]; }
        i = i + 1;
    }

    // Collect case constants BEFORE building the switch to avoid emitting loads
    // after the switch terminator (which would produce invalid IR).
    i8** case_consts = (i8**)malloc(sizeof(i8*) * (u64)s.cases_len);
    i32 j = 0;
    while (j < s.cases_len) {
        case_consts[j] = (i8*)0;
        if (!s.case_is_default[j]) {
            parser.expr_node* cv_expr = (parser.expr_node*)s.case_vals[j];
            if (cv_expr != (parser.expr_node*)0) {
                i8* cv = (i8*)0;
                // For identifier case values, try to get the constant without emitting loads.
                if (cv_expr.kind == ek_identifier) {
                    i8* gv = sv_map_get(&ctx.global_vars, cv_expr.str_val);
                    if (gv != (i8*)0) {
                        i8* init = LLVMGetInitializer(gv);
                        if (init != (i8*)0 && LLVMIsConstant(init)) { cv = init; }
                    }
                }
                // Fall back to visiting the expression (integer literals are already constant).
                if (cv == (i8*)0) { cv = visit_expr(cv_expr, ctx); }
                if (cv != (i8*)0 && LLVMIsConstant(cv)) {
                    case_consts[j] = coerce_int_val(cv, LLVMTypeOf(val), ctx.llvm_builder);
                }
            }
        }
        j = j + 1;
    }

    i8* sw = LLVMBuildSwitch(ctx.llvm_builder, val, default_bb, s.cases_len);

    // Add case entries (constants were already collected above).
    j = 0;
    while (j < s.cases_len) {
        if (!s.case_is_default[j] && case_consts[j] != (i8*)0) {
            LLVMAddCase(sw, case_consts[j], body_bbs[j]);
        }
        j = j + 1;
    }
    free((i8*)case_consts);

    // Emit case bodies
    ctx_push_loop(ctx, exit_bb, exit_bb);
    i32 k = 0;
    while (k < s.cases_len) {
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, body_bbs[k]);
        if (s.case_bodies[k] != (parser.block_stmt*)0) {
            visit_block_stmt(s.case_bodies[k], ctx);
        }
        if (!ctx_is_terminated(ctx)) {
            // Fall through to the next case (C semantics); branch to exit only for the last case.
            i8* fall_target = (k + 1 < s.cases_len) ? body_bbs[k + 1] : exit_bb;
            LLVMBuildBr(ctx.llvm_builder, fall_target);
        }
        k = k + 1;
    }
    ctx_pop_loop(ctx);

    free((i8*)body_bbs);
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, exit_bb);
}

// ---- return ----

void visit_return_stmt(parser.return_stmt* s, ir_context* ctx) {
    if (s.has_val) {
        i8* val = visit_expr(s.val, ctx);
        if (val != (i8*)0 && ctx.current_ret_type != (i8*)0) {
            val = coerce_int_val(val, ctx.current_ret_type, ctx.llvm_builder);
        }
        if (val != (i8*)0) {
            LLVMBuildRet(ctx.llvm_builder, val);
        } else {
            LLVMBuildRetVoid(ctx.llvm_builder);
        }
    } else {
        LLVMBuildRetVoid(ctx.llvm_builder);
    }
}

// ---- defer ----

void visit_defer_stmt_impl(parser.defer_stmt* s, ir_context* ctx) {
    if (s.is_block) {
        ctx_add_defer(ctx, s.blk, true);
    } else if (s.expr != (parser.expr_node*)0) {
        ctx_add_defer(ctx, (i8*)s.expr, false);
    }
}

// ---- Main statement dispatcher ----

void visit_stmt(parser.ast_node* node, ir_context* ctx) {
    if (node == (parser.ast_node*)0) { return; }
    i32 kind = node.kind;

    if (kind == nd_block) {
        visit_block_stmt((parser.block_stmt*)node, ctx);
        return;
    }
    if (kind == nd_expr_stmt) {
        parser.expr_stmt* es = (parser.expr_stmt*)node;
        visit_expr(es.expr, ctx);
        return;
    }
    if (kind == nd_var_decl) {
        visit_local_var_decl((parser.var_decl*)node, ctx);
        return;
    }
    if (kind == nd_return_stmt) {
        visit_return_stmt((parser.return_stmt*)node, ctx);
        return;
    }
    if (kind == nd_break_stmt) {
        i8* bb = ctx_current_break(ctx);
        if (bb != (i8*)0) {
            LLVMBuildBr(ctx.llvm_builder, bb);
        }
        return;
    }
    if (kind == nd_continue_stmt) {
        i8* bb = ctx_current_continue(ctx);
        if (bb != (i8*)0) {
            LLVMBuildBr(ctx.llvm_builder, bb);
        }
        return;
    }
    if (kind == nd_if_stmt) {
        visit_if_stmt((parser.if_stmt*)node, ctx);
        return;
    }
    if (kind == nd_while_stmt) {
        visit_while_stmt((parser.while_stmt*)node, ctx);
        return;
    }
    if (kind == nd_for_stmt) {
        visit_for_stmt((parser.for_stmt*)node, ctx);
        return;
    }
    if (kind == nd_switch_stmt) {
        visit_switch_stmt((parser.switch_stmt*)node, ctx);
        return;
    }
    if (kind == nd_defer_stmt || kind == nd_errdefer_stmt) {
        visit_defer_stmt_impl((parser.defer_stmt*)node, ctx);
        return;
    }
    if (kind == nd_asm_stmt) {
        // Inline ASM: emit as a call to inline asm string
        // (simplified: just no-op for bootstrap)
        return;
    }
    if (kind == nd_try_expr_stmt) {
        parser.try_expr_stmt* ts = (parser.try_expr_stmt*)node;
        visit_expr(ts.expr, ctx);
        return;
    }
    // Other statement kinds (declarations) handled by decls.arc
}

} // namespace ir
