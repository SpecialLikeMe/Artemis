// Statement IR generation for the Artemis self-hosting compiler.

namespace ir {

// Forward declarations
void visit_stmt(parser.ast_node* node, ir_context* ctx);
void visit_block_stmt(parser.block_stmt* blk, ir_context* ctx);
bool constexpr_eval_expr(parser.expr_node* e, ir_context* ctx, i64* out);
// Forward declaration for decls.arc function (included after stmts.arc)
void visit_top_level_decl(parser.ast_node* node, ir_context* ctx);

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

    // static local: backed by a module-level global with a one-time init flag
    if (d.is_static_local) {
        i8* alloca_t = llvm_type_of(d.type, ctx);

        // Build unique names using a per-module counter
        i8 gname[256];
        i8 fname[256];
        ctx.static_local_count = ctx.static_local_count + 1;
        snprintf(gname, (u64)256, "__stloc_%s_%d", d.name, ctx.static_local_count);
        snprintf(fname, (u64)256, "__stloc_%s_%d_init", d.name, ctx.static_local_count);

        // Create or reuse the global variable
        i8* gv = LLVMGetNamedGlobal(ctx.llvm_mod, gname);
        if (gv == (i8*)0) {
            gv = LLVMAddGlobal(ctx.llvm_mod, alloca_t, gname);
            LLVMSetInitializer(gv, LLVMConstNull(alloca_t));
            LLVMSetLinkage(gv, 3); // internal linkage
        }

        // Create or reuse the i1 init-done flag global
        i8* i1_t = LLVMInt1TypeInContext(ctx.llvm_ctx);
        i8* fv = LLVMGetNamedGlobal(ctx.llvm_mod, fname);
        if (fv == (i8*)0) {
            fv = LLVMAddGlobal(ctx.llvm_mod, i1_t, fname);
            LLVMSetInitializer(fv, LLVMConstNull(i1_t));
            LLVMSetLinkage(fv, 3);
        }

        // Insert: if (!init_flag) { init_flag = true; *gv = init_val; }
        i8* cur_fn = ctx.current_func;
        i8* init_bb  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, cur_fn, "stloc_init");
        i8* cont_bb  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, cur_fn, "stloc_cont");
        i8* flag_val = LLVMBuildLoad2(ctx.llvm_builder, i1_t, fv, "stloc_flag");
        LLVMBuildCondBr(ctx.llvm_builder, flag_val, cont_bb, init_bb);

        LLVMPositionBuilderAtEnd(ctx.llvm_builder, init_bb);
        LLVMBuildStore(ctx.llvm_builder, LLVMConstInt(i1_t, (u64)1, false), fv);
        if (d.has_init && d.init != (parser.expr_node*)0) {
            i8* init_val = visit_expr(d.init, ctx);
            if (init_val != (i8*)0) {
                init_val = coerce_int_val(init_val, alloca_t, ctx.llvm_builder);
                LLVMBuildStore(ctx.llvm_builder, init_val, gv);
            }
        }
        LLVMBuildBr(ctx.llvm_builder, cont_bb);

        LLVMPositionBuilderAtEnd(ctx.llvm_builder, cont_bb);

        // Register the global as a local so name lookup returns it
        i8* is_uns_b = (i8*)0;
        bool is_uns = is_unsigned_type_node(d.type);
        bool is_vol = (d.type != (parser.type_node*)0) && d.type.is_volatile;
        i8* elem_t = alloca_t;
        if (LLVMGetTypeKind(alloca_t) == LLVMArrayTypeKind) {
            elem_t = LLVMGetElementType(alloca_t);
        }
        i8* deref_t = (i8*)0;
        if (d.type != (parser.type_node*)0 && !d.type.is_func_ptr && d.type.pointer_depth > 0) {
            parser.type_node resolved;
            resolved = *d.type;
            resolved.pointer_depth = resolved.pointer_depth - 1;
            deref_t = llvm_type_of(&resolved, ctx);
        }
        i8* local_t = (LLVMGetTypeKind(alloca_t) == LLVMArrayTypeKind) ? alloca_t : elem_t;
        if (is_vol) {
            ctx_declare_local_volatile(ctx, d.name, gv, local_t, deref_t, is_uns);
        } else {
            ctx_declare_local(ctx, d.name, gv, local_t, deref_t, is_uns);
        }
        return;
    }

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

    // Auto type inference: if type resolved to void (e.g. `using let = auto;`),
    // evaluate init first to infer the actual type.
    i8* pre_init_val = (i8*)0;
    bool used_pre_init = false;
    if (tk == LLVMVoidTypeKind && d.has_init && d.init != (parser.expr_node*)0) {
        pre_init_val = visit_expr(d.init, ctx);
        if (pre_init_val != (i8*)0) {
            i8* inferred = LLVMTypeOf(pre_init_val);
            if (LLVMGetTypeKind(inferred) != LLVMVoidTypeKind) {
                alloca_t = inferred;
                elem_t   = alloca_t;
                tk       = LLVMGetTypeKind(alloca_t);
                used_pre_init = true;
            }
        }
    }

    i8* alloca = LLVMBuildAlloca(ctx.llvm_builder, alloca_t, d.name);
    bool is_uns = is_unsigned_type_node(d.type);
    bool is_vol = (d.type != (parser.type_node*)0) && d.type.is_volatile;
    // For arrays, store the full array type so subscript GEP can safely get element type.
    i8* local_t = (tk == LLVMArrayTypeKind) ? alloca_t : elem_t;
    if (is_vol) {
        ctx_declare_local_volatile(ctx, d.name, alloca, local_t, deref_t, is_uns);
    } else {
        ctx_declare_local(ctx, d.name, alloca, local_t, deref_t, is_uns);
    }

    // For function pointer locals, store the function type so indirect calls work
    // in LLVM opaque-pointer mode (where LLVMGetElementType on ptr is null).
    if (d.type != (parser.type_node*)0 && d.type.is_func_ptr) {
        i8* fn_ty = llvm_func_type_of(d.type, ctx);
        if (fn_ty != (i8*)0) {
            ctx_declare_local_func_type(ctx, d.name, fn_ty);
        }
    }

    // Propagate type to implicit struct literals: Vec2 v = .{.x=1, .y=2}
    if (d.has_init && d.init != (parser.expr_node*)0 &&
            d.init.kind == ek_class_init && d.init.is_implicit_init &&
            d.init.init_type == (parser.type_node*)0) {
        d.init.init_type = d.type;
    }

    if (d.has_init) {
        // Thread the declared pointer depth into the context so that the ref_expr handler
        // can build the correct number of indirection levels (depth 1 = &x, depth 2 = &&x, ...).
        if (!used_pre_init && d.init != (parser.expr_node*)0 && d.init.kind == ek_ref_expr && d.type != (parser.type_node*)0) {
            ctx.ref_target_depth = d.type.pointer_depth;
        }
        i8* init_val = used_pre_init ? pre_init_val : visit_expr(d.init, ctx);
        ctx.ref_target_depth = 0;
        if (init_val != (i8*)0) {
            // If the initializer was a lambda, register its function type for indirect calls
            if (d.init != (parser.expr_node*)0 && d.init.kind == ek_lambda) {
                i8* fn_t = LLVMGlobalGetValueType(init_val);
                if (fn_t != (i8*)0 && LLVMGetTypeKind(fn_t) == LLVMFunctionTypeKind) {
                    ctx_declare_local_func_type(ctx, d.name, fn_t);
                }
            }
            init_val = coerce_int_val(init_val, alloca_t, ctx.llvm_builder);
            LLVMBuildStore(ctx.llvm_builder, init_val, alloca);
        } else {
            LLVMBuildStore(ctx.llvm_builder, LLVMConstNull(alloca_t), alloca);
        }
    } else {
        LLVMBuildStore(ctx.llvm_builder, LLVMConstNull(alloca_t), alloca);
    }

    // Constructor call: TypeName varname(args...) or auto no-arg constructor
    if (d.has_ctor_parens || (!d.has_init && LLVMGetTypeKind(alloca_t) == LLVMStructTypeKind)) {
        i8* sname = (i8*)0;
        if (LLVMGetTypeKind(alloca_t) == LLVMStructTypeKind) {
            sname = LLVMGetStructName(alloca_t);
        }
        if (sname == (i8*)0 && d.type != (parser.type_node*)0) {
            sname = d.type.name;
        }
        if (sname != (i8*)0) {
            i8 ctor_name[512];
            snprintf(ctor_name, (u64)512, "%s__NS___construct__", sname);
            i8* ctor_fn = sv_map_get(&ctx.global_funcs, ctor_name);
            i8* ctor_ft = st_map_get(&ctx.global_func_types, ctor_name);
            if (ctor_fn != (i8*)0 && ctor_ft != (i8*)0) {
                u32 nparams = LLVMCountParamTypes(ctor_ft);
                // Only call constructor when explicitly requested with parens
                bool call_ctor = d.has_ctor_parens;
                if (call_ctor) {
                    i32 nctorargs = d.ctor_args_len + 1;
                    i8** cargs = (i8**)arc_malloc(sizeof(i8*) * (u64)nctorargs);
                    cargs[0] = alloca;
                    i8** param_ts = (i8**)arc_malloc(sizeof(i8*) * (u64)(nparams + 1));
                    if (nparams > 0) { LLVMGetParamTypes(ctor_ft, param_ts); }
                    i32 ci = 0;
                    while (ci < d.ctor_args_len) {
                        i8* av = visit_expr((parser.expr_node*)d.ctor_args[ci], ctx);
                        i32 pi = ci + 1;
                        if (av != (i8*)0 && (u32)pi < nparams) {
                            i32 pk = LLVMGetTypeKind(param_ts[pi]);
                            i8* av_ty = LLVMTypeOf(av);
                            i32 av_k = LLVMGetTypeKind(av_ty);
                            if (pk == LLVMStructTypeKind && ctx.memstr_fat_type != (i8*)0 &&
                                    param_ts[pi] == ctx.memstr_fat_type && av_k == LLVMStructTypeKind) {
                                i8* sname = LLVMGetStructName(av_ty);
                                i8* vtbl = (sname != (i8*)0) ? sv_map_get(&ctx.memstr_vtables, sname) : (i8*)0;
                                i8* tmp = LLVMBuildAlloca(ctx.llvm_builder, av_ty, "ms_tmp");
                                LLVMBuildStore(ctx.llvm_builder, av, tmp);
                                i8* fat = LLVMGetUndef(ctx.memstr_fat_type);
                                fat = LLVMBuildInsertValue(ctx.llvm_builder, fat, tmp, 0, "fat_d");
                                i8* ptr_t = LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
                                i8* vp = (vtbl != (i8*)0) ? vtbl : LLVMConstPointerNull(ptr_t);
                                fat = LLVMBuildInsertValue(ctx.llvm_builder, fat, vp, 1, "fat_v");
                                av = fat;
                            } else if (pk == LLVMPointerTypeKind && av_k == LLVMStructTypeKind) {
                                i8* tmp = LLVMBuildAlloca(ctx.llvm_builder, av_ty, "ref_tmp");
                                LLVMBuildStore(ctx.llvm_builder, av, tmp);
                                av = tmp;
                            } else {
                                av = coerce_int_val(av, param_ts[pi], ctx.llvm_builder);
                            }
                        }
                        cargs[ci + 1] = av;
                        ci = ci + 1;
                    }
                    arc_free((i8*)param_ts);
                    LLVMBuildCall2(ctx.llvm_builder, ctor_ft, ctor_fn, cargs, nctorargs, "");
                    arc_free((i8*)cargs);
                }
            }
        }
    }
}

// ---- if/else ----

void visit_if_stmt(parser.if_stmt* s, ir_context* ctx) {
    // comptime if: evaluate condition at compile time, emit only the taken branch.
    if (s.is_constexpr && s.cond != (parser.expr_node*)0) {
        i64 cval = 0;
        bool ok = constexpr_eval_expr(s.cond, ctx, &cval);
        if (!ok) {
            // Fall through to runtime path if we can't evaluate at compile time
        } else {
            if (cval != 0) {
                if (s.then_body != (parser.ast_node*)0) { visit_stmt(s.then_body, ctx); }
            } else {
                if (s.else_body != (parser.ast_node*)0) { visit_stmt(s.else_body, ctx); }
            }
            return;
        }
    }

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
    bool then_terminated = ctx_is_terminated(ctx);
    if (!then_terminated) {
        LLVMBuildBr(ctx.llvm_builder, merge_bb);
    }

    // Else branch (if present)
    bool else_terminated = false;
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
        else_terminated = ctx_is_terminated(ctx);
        if (!else_terminated) {
            LLVMBuildBr(ctx.llvm_builder, merge_bb);
        }
    }

    LLVMPositionBuilderAtEnd(ctx.llvm_builder, merge_bb);
    // Both branches terminated → merge_bb has no predecessors; mark unreachable
    // so ctx_is_terminated() is true at the function end.
    // Only applies when an else branch exists; without one, the false path arrives here.
    if (then_terminated && else_bb_ptr != (i8*)0 && else_terminated) {
        LLVMBuildUnreachable(ctx.llvm_builder);
    }
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

// ---- for range ----

void visit_for_range_stmt(parser.for_range_stmt* s, ir_context* ctx) {
    i8* fn       = ctx.current_func;
    i8* cond_bb  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "range_cond");
    i8* body_bb  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "range_body");
    i8* step_bb  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "range_step");
    i8* exit_bb  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "range_exit");

    // Need the lvalue of the range container to call begin()/end() methods on it
    i8* range_lval = (i8*)0;
    if (s.range != (parser.expr_node*)0) {
        range_lval = visit_lvalue(s.range, ctx);
    }
    i8* range_val = (i8*)0;
    if (range_lval != (i8*)0) {
        range_val = range_lval; // treat as pointer to container
    } else if (s.range != (parser.expr_node*)0) {
        range_val = visit_expr(s.range, ctx);
    }

    i8* elem_llvm_t;
    if (s.var_type != (parser.type_node*)0) {
        elem_llvm_t = llvm_type_of(s.var_type, ctx);
    } else {
        elem_llvm_t = LLVMInt8TypeInContext(ctx.llvm_ctx);
    }

    i8* i64t = LLVMInt64TypeInContext(ctx.llvm_ctx);
    i8* ptr_t = LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
    i8* count_val = (i8*)0;

    // ---- Fixed-size C array path ----
    // for (T x : arr) where arr is declared as T arr[N]
    if (s.range != (parser.expr_node*)0 && s.range.kind == ek_identifier && range_lval != (i8*)0) {
        i8* arr_type = ctx_lookup_local_type(ctx, s.range.str_val);
        if (arr_type != (i8*)0 && LLVMGetTypeKind(arr_type) == LLVMArrayTypeKind) {
            u32 arr_len = LLVMGetArrayLength(arr_type);
            count_val = LLVMConstInt(i64t, (u64)arr_len, false);
            i8* elem_t = LLVMGetElementType(arr_type);
            if (elem_t != (i8*)0 && s.var_type == (parser.type_node*)0) {
                elem_llvm_t = elem_t;
            }
            // Decay array alloca to pointer to first element via two-index GEP
            i8* zero32 = LLVMConstInt(LLVMInt32TypeInContext(ctx.llvm_ctx), 0u, false);
            i8* gep_idx[2];
            gep_idx[0] = zero32;
            gep_idx[1] = zero32;
            range_val = LLVMBuildGEP2(ctx.llvm_builder, arr_type, range_lval, gep_idx, 2, "arr_decay");
        }
    }

    // ---- begin()/end() iterator protocol ----
    // If the container type has begin() and end() methods, use pointer iteration.
    // The loop becomes: it = begin(); end_it = end(); while (it != end_it) { x = *it; ...; ++it; }
    i8* use_iter_begin = (i8*)0; // begin pointer
    i8* use_iter_end   = (i8*)0; // end pointer

    if (s.range != (parser.expr_node*)0) {
        i8* struct_t = infer_expr_struct_type(s.range, ctx);
        if (struct_t != (i8*)0) {
            i8* sname = LLVMGetStructName(struct_t);
            if (sname != (i8*)0) {
                // Look for begin method: SNAME__MT_begin or SNAME__NS_begin
                i8 begin_name[256];
                i8 end_name[256];
                snprintf(begin_name, (u64)256, "%s__MT_begin", sname);
                snprintf(end_name,   (u64)256, "%s__MT_end",   sname);
                i8* begin_fn    = sv_map_get(&ctx.global_funcs,      begin_name);
                i8* begin_fn_ty = st_map_get(&ctx.global_func_types, begin_name);
                i8* end_fn      = sv_map_get(&ctx.global_funcs,      end_name);
                i8* end_fn_ty   = st_map_get(&ctx.global_func_types, end_name);
                // Fallback: istruc/namespace methods use __NS_ prefix
                if (begin_fn == (i8*)0 || begin_fn_ty == (i8*)0) {
                    snprintf(begin_name, (u64)256, "%s__NS_begin", sname);
                    snprintf(end_name,   (u64)256, "%s__NS_end",   sname);
                    begin_fn    = sv_map_get(&ctx.global_funcs,      begin_name);
                    begin_fn_ty = st_map_get(&ctx.global_func_types, begin_name);
                    end_fn      = sv_map_get(&ctx.global_funcs,      end_name);
                    end_fn_ty   = st_map_get(&ctx.global_func_types, end_name);
                }
                if (begin_fn != (i8*)0 && begin_fn_ty != (i8*)0 &&
                        end_fn != (i8*)0 && end_fn_ty != (i8*)0) {
                    // Ensure we have a pointer to the container for self param
                    i8* self_ptr = range_lval;
                    if (self_ptr == (i8*)0 && range_val != (i8*)0) {
                        // Materialize on stack
                        i8* tmp = LLVMBuildAlloca(ctx.llvm_builder, struct_t, "rng_tmp");
                        LLVMBuildStore(ctx.llvm_builder, range_val, tmp);
                        self_ptr = tmp;
                    }
                    if (self_ptr != (i8*)0) {
                        use_iter_begin = LLVMBuildCall2(ctx.llvm_builder, begin_fn_ty, begin_fn, &self_ptr, 1, "rng_begin");
                        use_iter_end   = LLVMBuildCall2(ctx.llvm_builder, end_fn_ty,   end_fn,   &self_ptr, 1, "rng_end");
                        // Infer elem type from begin() return type (pointer pointee)
                        if (s.var_type == (parser.type_node*)0 && use_iter_begin != (i8*)0) {
                            elem_llvm_t = LLVMInt32TypeInContext(ctx.llvm_ctx); // fallback i32
                        }
                    }
                }

                if (use_iter_begin == (i8*)0) {
                    // Fall back to length/data field protocol
                    struct_meta* sm = struct_meta_find(&ctx.struct_meta_tbl, sname);
                    if (sm != (struct_meta*)0) {
                        bool range_is_ptr = (range_val != (i8*)0 && LLVMGetTypeKind(LLVMTypeOf(range_val)) == LLVMPointerTypeKind);
                        i32 li = 0;
                        while (li < sm.field_names.len && count_val == (i8*)0) {
                            if (strcmp(sm.field_names.data[li], "length") == 0 || strcmp(sm.field_names.data[li], "size") == 0 || strcmp(sm.field_names.data[li], "len") == 0) {
                                i8* ft = (li < sm.field_types.len) ? sm.field_types.data[li] : i64t;
                                if (ft == (i8*)0) { ft = i64t; }
                                if (range_is_ptr) {
                                    i8* gep = LLVMBuildStructGEP2(ctx.llvm_builder, struct_t, range_val, (u32)li, "len_ptr");
                                    count_val = LLVMBuildLoad2(ctx.llvm_builder, ft, gep, "range_len");
                                } else if (range_val != (i8*)0) {
                                    count_val = LLVMBuildExtractValue(ctx.llvm_builder, range_val, (u32)li, "range_len");
                                }
                            }
                            li = li + 1;
                        }
                        i32 pi = 0;
                        while (pi < sm.field_types.len) {
                            i8* fpt = sm.field_types.data[pi];
                            if (fpt != (i8*)0 && LLVMGetTypeKind(fpt) == LLVMPointerTypeKind) {
                                if (range_is_ptr) {
                                    i8* gep2 = LLVMBuildStructGEP2(ctx.llvm_builder, struct_t, range_val, (u32)pi, "data_ptr");
                                    range_val = LLVMBuildLoad2(ctx.llvm_builder, fpt, gep2, "range_data");
                                } else if (range_val != (i8*)0) {
                                    range_val = LLVMBuildExtractValue(ctx.llvm_builder, range_val, (u32)pi, "range_data");
                                }
                                break;
                            }
                            pi = pi + 1;
                        }
                    }
                }
            }
        }
    }

    // ---- begin/end pointer iterator path ----
    if (use_iter_begin != (i8*)0 && use_iter_end != (i8*)0) {
        // Store begin and end into allocas so we can mutate them
        i8* it_alloca  = LLVMBuildAlloca(ctx.llvm_builder, ptr_t, "rng_it");
        i8* end_alloca = LLVMBuildAlloca(ctx.llvm_builder, ptr_t, "rng_end");
        LLVMBuildStore(ctx.llvm_builder, use_iter_begin, it_alloca);
        LLVMBuildStore(ctx.llvm_builder, use_iter_end,   end_alloca);

        i8* var_name = s.var_name;
        if (var_name == (i8*)0) { var_name = "elem"; }
        i8* elem_alloca = LLVMBuildAlloca(ctx.llvm_builder, elem_llvm_t, var_name);

        LLVMBuildBr(ctx.llvm_builder, cond_bb);

        // Cond: it != end
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, cond_bb);
        i8* it_cur  = LLVMBuildLoad2(ctx.llvm_builder, ptr_t, it_alloca,  "it");
        i8* end_cur = LLVMBuildLoad2(ctx.llvm_builder, ptr_t, end_alloca, "end");
        i8* cond_v  = LLVMBuildICmp(ctx.llvm_builder, LLVMIntNE, it_cur, end_cur, "it_ne_end");
        LLVMBuildCondBr(ctx.llvm_builder, cond_v, body_bb, exit_bb);

        // Body: *it
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, body_bb);
        ctx_push_scope(ctx);
        i8* it_body = LLVMBuildLoad2(ctx.llvm_builder, ptr_t, it_alloca, "it_body");
        i8* elem_v  = LLVMBuildLoad2(ctx.llvm_builder, elem_llvm_t, it_body, "elem_deref");
        LLVMBuildStore(ctx.llvm_builder, elem_v, elem_alloca);
        ctx_declare_local(ctx, var_name, elem_alloca, elem_llvm_t, (i8*)0, false);
        ctx_push_loop(ctx, exit_bb, step_bb);
        visit_stmt(s.body, ctx);
        ctx_pop_loop(ctx);
        if (!ctx_is_terminated(ctx)) { LLVMBuildBr(ctx.llvm_builder, step_bb); }
        ctx_pop_scope(ctx);

        // Step: ++it
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, step_bb);
        i8* it_step = LLVMBuildLoad2(ctx.llvm_builder, ptr_t, it_alloca, "it_step");
        i8* one     = LLVMConstInt(LLVMInt64TypeInContext(ctx.llvm_ctx), 1u, 0);
        i8* it_next = LLVMBuildGEP2(ctx.llvm_builder, elem_llvm_t, it_step, &one, 1, "it_inc");
        LLVMBuildStore(ctx.llvm_builder, it_next, it_alloca);
        LLVMBuildBr(ctx.llvm_builder, cond_bb);

        LLVMPositionBuilderAtEnd(ctx.llvm_builder, exit_bb);
        return;
    }

    // ---- index/count path (fallback) ----
    if (count_val == (i8*)0) {
        count_val = LLVMConstInt(i64t, 0u, 0);
    }
    count_val = coerce_int_val(count_val, i64t, ctx.llvm_builder);

    i8* idx_alloca = LLVMBuildAlloca(ctx.llvm_builder, i64t, "range_idx");
    LLVMBuildStore(ctx.llvm_builder, LLVMConstInt(i64t, 0u, 0), idx_alloca);

    i8* var_name = s.var_name;
    if (var_name == (i8*)0) { var_name = "elem"; }
    i8* elem_alloca = LLVMBuildAlloca(ctx.llvm_builder, elem_llvm_t, var_name);

    LLVMBuildBr(ctx.llvm_builder, cond_bb);

    // Condition: idx < count
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, cond_bb);
    i8* idx_cur = LLVMBuildLoad2(ctx.llvm_builder, i64t, idx_alloca, "idx");
    i8* cond_v  = LLVMBuildICmp(ctx.llvm_builder, LLVMIntULT, idx_cur, count_val, "range_lt");
    LLVMBuildCondBr(ctx.llvm_builder, cond_v, body_bb, exit_bb);

    // Body: load element and run body
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, body_bb);
    ctx_push_scope(ctx);
    if (range_val != (i8*)0) {
        i8* elem_ptr = LLVMBuildGEP2(ctx.llvm_builder, elem_llvm_t, range_val, &idx_cur, 1, "elem_ptr");
        i8* elem_val = LLVMBuildLoad2(ctx.llvm_builder, elem_llvm_t, elem_ptr, "elem");
        LLVMBuildStore(ctx.llvm_builder, elem_val, elem_alloca);
    }
    ctx_declare_local(ctx, var_name, elem_alloca, elem_llvm_t, (i8*)0, false);
    ctx_push_loop(ctx, exit_bb, step_bb);
    visit_stmt(s.body, ctx);
    ctx_pop_loop(ctx);
    if (!ctx_is_terminated(ctx)) { LLVMBuildBr(ctx.llvm_builder, step_bb); }
    ctx_pop_scope(ctx);

    // Step: idx++
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, step_bb);
    i8* idx_new = LLVMBuildAdd(ctx.llvm_builder, idx_cur, LLVMConstInt(i64t, 1u, 0), "idx_inc");
    LLVMBuildStore(ctx.llvm_builder, idx_new, idx_alloca);
    LLVMBuildBr(ctx.llvm_builder, cond_bb);

    LLVMPositionBuilderAtEnd(ctx.llvm_builder, exit_bb);
}

// ---- switch ----

void visit_switch_stmt(parser.switch_stmt* s, ir_context* ctx) {
    i8* val = visit_expr(s.val, ctx);
    if (val == (i8*)0) { return; }

    i8* fn       = ctx.current_func;
    i8* exit_bb  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "sw_exit");
    i8* default_bb = exit_bb;

    // Build body blocks
    i8** body_bbs = (i8**)arc_malloc(sizeof(i8*) * (u64)s.cases_len);
    i32 i = 0;
    while (i < s.cases_len) {
        body_bbs[i] = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "sw_case");
        if (s.case_is_default[i]) { default_bb = body_bbs[i]; }
        i = i + 1;
    }

    // Collect case constants BEFORE building the switch to avoid emitting loads
    // after the switch terminator (which would produce invalid IR).
    i8** case_consts = (i8**)arc_malloc(sizeof(i8*) * (u64)s.cases_len);
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
    arc_free((i8*)case_consts);

    // Emit case bodies
    ctx_push_loop(ctx, exit_bb, exit_bb);
    bool all_cases_ret = true;   // true only when every case terminates via ret/unreachable
    bool has_default = false;
    i32 k = 0;
    while (k < s.cases_len) {
        if (s.case_is_default[k]) { has_default = true; }
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, body_bbs[k]);
        if (s.case_bodies[k] != (parser.block_stmt*)0) {
            visit_block_stmt(s.case_bodies[k], ctx);
        }
        if (!ctx_is_terminated(ctx)) {
            all_cases_ret = false;
            // Fall through to the next case (C semantics); branch to exit only for the last case.
            i8* fall_target = (k + 1 < s.cases_len) ? body_bbs[k + 1] : exit_bb;
            LLVMBuildBr(ctx.llvm_builder, fall_target);
        } else {
            // Check if terminator is a branch (break) vs ret — break goes to exit_bb
            i8* bb_now = LLVMGetInsertBlock(ctx.llvm_builder);
            if (bb_now != (i8*)0) {
                i8* term = LLVMGetBasicBlockTerminator(bb_now);
                if (term != (i8*)0 && LLVMGetInstructionOpcode(term) != 1) {
                    // Not a ret (opcode 1) — must be br/break, so exit_bb is reachable
                    all_cases_ret = false;
                }
            }
        }
        k = k + 1;
    }
    ctx_pop_loop(ctx);

    arc_free((i8*)body_bbs);
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, exit_bb);
    // All cases (incl. default) returned → exit_bb has no predecessors; mark unreachable.
    if (all_cases_ret && has_default) {
        LLVMBuildUnreachable(ctx.llvm_builder);
    }
}

// ---- return ----

void visit_return_stmt(parser.return_stmt* s, ir_context* ctx) {
    // Evaluate return value before emitting defers (may reference stack vars).
    i8* val = (i8*)0;
    if (s.has_val) {
        val = visit_expr(s.val, ctx);
        if (val != (i8*)0 && ctx.current_ret_type != (i8*)0) {
            i8* ret_t = ctx.current_ret_type;
            i32 ret_k = LLVMGetTypeKind(ret_t);
            i8* val_t = LLVMTypeOf(val);
            i32 val_k = LLVMGetTypeKind(val_t);
            if (ret_k == LLVMStructTypeKind && val_k == LLVMPointerTypeKind) {
                val = LLVMBuildLoad2(ctx.llvm_builder, ret_t, val, "sret_load");
            } else {
                val = coerce_int_val(val, ret_t, ctx.llvm_builder);
            }
        }
    }

    // Emit all pending defers (innermost to outermost) before ret.
    i32 di = ctx.defers.len - 1;
    while (di >= 0) {
        emit_deferred(&ctx.defers.data[di], ctx);
        di = di - 1;
    }

    // Emit errdefers if returning an error (-1 sentinel) — only when there
    // are actual errdefer items and the return type is an integer (error-union pattern).
    bool has_errdefer = false;
    i32 ei_chk = ctx.errdefers.len - 1;
    while (ei_chk >= 0) {
        if (ctx.errdefers.data[ei_chk].len > 0) { has_errdefer = true; }
        ei_chk = ei_chk - 1;
    }
    if (s.has_val && val != (i8*)0 && has_errdefer) {
        i8* val_t = LLVMTypeOf(val);
        i32 val_kind = LLVMGetTypeKind(val_t);
        if (val_kind == LLVMIntegerTypeKind) {
            i8* i32_t = LLVMInt32TypeInContext(ctx.llvm_ctx);
            i8* coerced_ret = coerce_int_val(val, i32_t, ctx.llvm_builder);
            i64 minus_one_e = (i64)-1;
            i8* neg1_e = LLVMConstInt(i32_t, (u64)minus_one_e, 1);
            i8* is_err_val = LLVMBuildICmp(ctx.llvm_builder, LLVMIntEQ, coerced_ret, neg1_e, "is_err_ret");
            i8* fn_r   = ctx.current_func;
            i8* err_bb_r = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_r, "err_exit");
            i8* ok_bb_r  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_r, "ok_exit");
            LLVMBuildCondBr(ctx.llvm_builder, is_err_val, err_bb_r, ok_bb_r);
            // Error exit: emit errdefers
            LLVMPositionBuilderAtEnd(ctx.llvm_builder, err_bb_r);
            i32 ei = ctx.errdefers.len - 1;
            while (ei >= 0) {
                emit_deferred(&ctx.errdefers.data[ei], ctx);
                ei = ei - 1;
            }
            LLVMBuildRet(ctx.llvm_builder, val);
            // OK exit: no errdefers
            LLVMPositionBuilderAtEnd(ctx.llvm_builder, ok_bb_r);
            LLVMBuildRet(ctx.llvm_builder, val);
            return;
        }
    }

    if (s.has_val) {
        if (val != (i8*)0) {
            LLVMBuildRet(ctx.llvm_builder, val);
        } else if (ctx.current_ret_type != (i8*)0) {
            LLVMBuildRet(ctx.llvm_builder, LLVMGetUndef(ctx.current_ret_type));
        } else {
            LLVMBuildRetVoid(ctx.llvm_builder);
        }
    } else {
        LLVMBuildRetVoid(ctx.llvm_builder);
    }
}

// ---- defer ----

void visit_defer_stmt_impl(parser.defer_stmt* s, ir_context* ctx) {
    bool is_err = (s.kind == nd_errdefer_stmt);
    if (s.is_block) {
        if (is_err) { ctx_add_errdefer(ctx, s.blk, true); }
        else        { ctx_add_defer(ctx, s.blk, true); }
    } else if (s.expr != (parser.expr_node*)0) {
        if (is_err) { ctx_add_errdefer(ctx, (i8*)s.expr, false); }
        else        { ctx_add_defer(ctx, (i8*)s.expr, false); }
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
        // Macro expansion may produce a nd_var_decl embedded as the expr
        if (es.expr != (parser.expr_node*)0 && es.expr.kind == nd_var_decl) {
            visit_local_var_decl((parser.var_decl*)es.expr, ctx);
        } else {
            visit_expr(es.expr, ctx);
        }
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
    if (kind == nd_for_range_stmt) {
        visit_for_range_stmt((parser.for_range_stmt*)node, ctx);
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
        parser.asm_stmt* as = (parser.asm_stmt*)node;
        i8* raw = as.raw_instructions;
        if (raw == (i8*)0) { return; }
        i64 raw_len = (i64)strlen(raw);

        // Allocate flat buffers for each part (instructions, sec1, sec2, sec3)
        i8* part0 = (i8*)arc_malloc((u64)1536);
        i8* part1 = (i8*)arc_malloc((u64)512);
        i8* part2 = (i8*)arc_malloc((u64)512);
        i8* part3 = (i8*)arc_malloc((u64)512);
        part0[0] = 0; part1[0] = 0; part2[0] = 0; part3[0] = 0;
        i32 nparts = 0;
        i32 poff = 0;
        bool in_q = false;
        i64 ri = 0;
        while (ri < raw_len && nparts < 4) {
            i8 c = raw[ri];
            if (c == '"') { in_q = !in_q; }
            if (c == ':' && !in_q) {
                i8* cur_part = (nparts == 0 ? part0 : (nparts == 1 ? part1 : (nparts == 2 ? part2 : part3)));
                cur_part[poff] = 0;
                nparts = nparts + 1; poff = 0;
                i8* np = (nparts == 0 ? part0 : (nparts == 1 ? part1 : (nparts == 2 ? part2 : part3)));
                np[0] = 0;
            } else {
                i8* cur_part = (nparts == 0 ? part0 : (nparts == 1 ? part1 : (nparts == 2 ? part2 : part3)));
                i32 lim = (nparts == 0 ? 1535 : 511);
                if (poff < lim) { cur_part[poff] = c; poff = poff + 1; }
            }
            ri = ri + 1;
        }
        {
            i8* cur_part = (nparts == 0 ? part0 : (nparts == 1 ? part1 : (nparts == 2 ? part2 : part3)));
            cur_part[poff] = 0; nparts = nparts + 1;
        }
        if (nparts < 2) {
            arc_free(part0); arc_free(part1); arc_free(part2); arc_free(part3); return;
        }

        // Flat storage for constraints/varnames: 4 entries each, 64 bytes per entry
        i8* in_cstr_buf  = (i8*)arc_malloc((u64)256); // 4*64
        i8* in_var_buf   = (i8*)arc_malloc((u64)256);
        i8* out_cstr_buf = (i8*)arc_malloc((u64)256);
        i8* out_var_buf  = (i8*)arc_malloc((u64)256);
        i8* clob_buf     = (i8*)arc_malloc((u64)256);
        i32 in_cnt = 0; i32 out_cnt = 0; i32 clob_cnt = 0;

        // Helper macros inline: get pointer to entry i in a flat 64-byte-stride buffer
        // in_cstr(i) = in_cstr_buf + i*64
        // Parse sections: sec1→part1, sec2→part2, sec3→part3
        i32 sec = 1;
        while (sec < nparts && sec <= 3) {
            i8* sp = (sec == 1 ? part1 : (sec == 2 ? part2 : part3));
            i64 sp_len = (i64)strlen(sp);
            i64 si = 0;
            while (si < sp_len) {
                while (si < sp_len && (sp[si] == ' ' || sp[si] == '\t' || sp[si] == '\n' || sp[si] == '\r' || sp[si] == ',')) { si = si + 1; }
                if (si >= sp_len) { break; }
                if (sp[si] == '"') {
                    si = si + 1;
                    i8 cstr[64]; i32 ci = 0; bool is_out = false;
                    if (si < sp_len && sp[si] == '=') { is_out = true; si = si + 1; }
                    while (si < sp_len && sp[si] != '"' && ci < 63) { cstr[ci] = sp[si]; ci = ci + 1; si = si + 1; }
                    cstr[ci] = 0;
                    if (si < sp_len && sp[si] == '"') { si = si + 1; }
                    while (si < sp_len && (sp[si] == ' ' || sp[si] == '\t')) { si = si + 1; }
                    if (si < sp_len && sp[si] == '(') {
                        si = si + 1;
                        i8 vname[64]; i32 vi = 0;
                        while (si < sp_len && sp[si] != ')' && vi < 63) { vname[vi] = sp[si]; vi = vi + 1; si = si + 1; }
                        vname[vi] = 0;
                        if (si < sp_len && sp[si] == ')') { si = si + 1; }
                        if (is_out || sec == 2) {
                            if (out_cnt < 4) {
                                snprintf(out_cstr_buf + out_cnt * 64, (u64)64, "%s", cstr);
                                snprintf(out_var_buf  + out_cnt * 64, (u64)64, "%s", vname);
                                out_cnt = out_cnt + 1;
                            }
                        } else {
                            if (in_cnt < 4) {
                                snprintf(in_cstr_buf + in_cnt * 64, (u64)64, "%s", cstr);
                                snprintf(in_var_buf  + in_cnt * 64, (u64)64, "%s", vname);
                                in_cnt = in_cnt + 1;
                            }
                        }
                    } else {
                        if (clob_cnt < 4) { snprintf(clob_buf + clob_cnt * 64, (u64)64, "%s", cstr); clob_cnt = clob_cnt + 1; }
                    }
                } else if (sp[si] != 0) {
                    i8 tok[64]; i32 ti = 0;
                    while (si < sp_len && sp[si] != ' ' && sp[si] != '\t' && sp[si] != ',' && sp[si] != '\n' && ti < 63) { tok[ti] = sp[si]; ti = ti + 1; si = si + 1; }
                    tok[ti] = 0;
                    if (ti > 0 && clob_cnt < 4) { snprintf(clob_buf + clob_cnt * 64, (u64)64, "%s", tok); clob_cnt = clob_cnt + 1; }
                } else { si = si + 1; }
            }
            sec = sec + 1;
        }

        // Build substituted instruction string from part0
        i8* instr_subst = (i8*)arc_malloc((u64)2048);
        i32 is_off = 0;
        i8* ip = part0;
        i64 ip_len = (i64)strlen(ip);
        i64 ii = 0;
        while (ii < ip_len && is_off < 2045) {
            if (ip[ii] == '%') {
                ii = ii + 1;
                i8 vn[64]; i32 vni = 0;
                while (ii < ip_len && (isalpha((i32)ip[ii]) || isdigit((i32)ip[ii]) || ip[ii] == '_') && vni < 63) { vn[vni] = ip[ii]; vni = vni + 1; ii = ii + 1; }
                vn[vni] = 0;
                i32 idx = -1;
                i32 ki = 0;
                while (ki < out_cnt && idx < 0) { if (strcmp(out_var_buf + ki*64, vn) == 0) { idx = ki; } ki = ki + 1; }
                ki = 0;
                while (ki < in_cnt && idx < 0) { if (strcmp(in_var_buf + ki*64, vn) == 0) { idx = out_cnt + ki; } ki = ki + 1; }
                if (idx >= 0) {
                    i8 repl[16]; snprintf(repl, (u64)16, "$%d", idx);
                    i64 rl = (i64)strlen(repl); i64 ri2 = 0;
                    while (ri2 < rl && is_off < 2045) { instr_subst[is_off] = repl[ri2]; is_off = is_off + 1; ri2 = ri2 + 1; }
                } else {
                    instr_subst[is_off] = '%'; is_off = is_off + 1;
                    i64 vni2 = 0;
                    while (vni2 < (i64)vni && is_off < 2045) { instr_subst[is_off] = vn[vni2]; is_off = is_off + 1; vni2 = vni2 + 1; }
                }
            } else if (ip[ii] == '$') {
                if (is_off + 1 < 2045) { instr_subst[is_off] = '$'; instr_subst[is_off+1] = '$'; is_off = is_off + 2; }
                ii = ii + 1;
            } else if (ip[ii] == '\n') {
                // Pass actual newline byte — LLVMGetInlineAsm expects raw bytes
                if (is_off < 2045) { instr_subst[is_off] = '\n'; is_off = is_off + 1; }
                ii = ii + 1;
            } else { instr_subst[is_off] = ip[ii]; is_off = is_off + 1; ii = ii + 1; }
        }
        instr_subst[is_off] = 0;

        // Build constraint string
        i8* con_str = (i8*)arc_malloc((u64)512);
        con_str[0] = 0; i32 co = 0;
        i32 oci = 0;
        while (oci < out_cnt) {
            if (co > 0) { con_str[co] = ','; co = co + 1; }
            con_str[co] = '='; co = co + 1;
            i8* ocs = out_cstr_buf + oci*64;
            i64 ocl = (i64)strlen(ocs); i64 j = 0;
            while (j < ocl && co < 510) { con_str[co] = ocs[j]; co = co + 1; j = j + 1; }
            oci = oci + 1;
        }
        i32 ici = 0;
        while (ici < in_cnt) {
            if (co > 0) { con_str[co] = ','; co = co + 1; }
            i8* ics = in_cstr_buf + ici*64;
            i64 icl = (i64)strlen(ics); i64 j = 0;
            while (j < icl && co < 510) { con_str[co] = ics[j]; co = co + 1; j = j + 1; }
            ici = ici + 1;
        }
        i32 cli = 0;
        while (cli < clob_cnt) {
            if (co > 0) { con_str[co] = ','; co = co + 1; }
            if (co + 3 < 510) { con_str[co] = '~'; con_str[co+1] = '{'; co = co + 2; }
            i8* cs = clob_buf + cli*64;
            i64 cl = (i64)strlen(cs); i64 j = 0;
            while (j < cl && co < 508) { con_str[co] = cs[j]; co = co + 1; j = j + 1; }
            if (co < 510) { con_str[co] = '}'; co = co + 1; }
            cli = cli + 1;
        }
        con_str[co] = 0;

        // Collect input LLVM values and types
        i8** in_vals  = (i8**)arc_malloc(sizeof(i8*) * (u64)(in_cnt > 0 ? in_cnt : 1));
        i8** in_types_a = (i8**)arc_malloc(sizeof(i8*) * (u64)(in_cnt > 0 ? in_cnt : 1));
        i32 ivi = 0;
        while (ivi < in_cnt) {
            i8* ivn = in_var_buf + ivi*64;
            i8* iv  = ctx_lookup_local(ctx, ivn);
            i8* it  = ctx_lookup_local_type(ctx, ivn);
            if (iv != (i8*)0 && it != (i8*)0) {
                in_vals[ivi]    = LLVMBuildLoad2(ctx.llvm_builder, it, iv, ivn);
                in_types_a[ivi] = it;
            } else { in_vals[ivi] = (i8*)0; in_types_a[ivi] = LLVMInt32TypeInContext(ctx.llvm_ctx); }
            ivi = ivi + 1;
        }
        i8* ret_t = (out_cnt == 1) ? (i8*)0 : LLVMVoidTypeInContext(ctx.llvm_ctx);
        if (out_cnt == 1) {
            i8* ovt = ctx_lookup_local_type(ctx, out_var_buf);
            ret_t = (ovt != (i8*)0) ? ovt : LLVMInt32TypeInContext(ctx.llvm_ctx);
        }
        i8* fn_ty = LLVMFunctionType(ret_t, in_types_a, in_cnt, 0);
        i64 istr_len = (i64)strlen(instr_subst);
        i64 cstr_len = (i64)strlen(con_str);
        i8* asm_val = LLVMGetInlineAsm(fn_ty, instr_subst, (u64)istr_len, con_str, (u64)cstr_len, 1, 0, 1, 0);
        i8* call_res = LLVMBuildCall2(ctx.llvm_builder, fn_ty, asm_val, in_vals, in_cnt, out_cnt > 0 ? "asm_out" : "");
        if (out_cnt == 1 && call_res != (i8*)0) {
            i8* ov = ctx_lookup_local(ctx, out_var_buf);
            if (ov != (i8*)0) { LLVMBuildStore(ctx.llvm_builder, call_res, ov); }
        }
        arc_free(part0); arc_free(part1); arc_free(part2); arc_free(part3);
        arc_free(in_cstr_buf); arc_free(in_var_buf); arc_free(out_cstr_buf); arc_free(out_var_buf); arc_free(clob_buf);
        arc_free(instr_subst); arc_free(con_str); arc_free(in_vals); arc_free(in_types_a);
        return;
    }
    if (kind == nd_try_expr_stmt) {
        parser.try_expr_stmt* ts = (parser.try_expr_stmt*)node;
        i8* tv = visit_expr(ts.expr, ctx);
        if (tv == (i8*)0) { return; }
        i8* tv_t = LLVMTypeOf(tv);
        if (LLVMGetTypeKind(tv_t) != LLVMIntegerTypeKind) { return; }
        i8* i32_t_s = LLVMInt32TypeInContext(ctx.llvm_ctx);
        i8* coerced_s = coerce_int_val(tv, i32_t_s, ctx.llvm_builder);
        i64 minus1_s = (i64)-1;
        i8* neg1_s = LLVMConstInt(i32_t_s, (u64)minus1_s, 1);
        i8* is_err_s = LLVMBuildICmp(ctx.llvm_builder, LLVMIntEQ, coerced_s, neg1_s, "ts_is_err");
        i8* fn_s   = ctx.current_func;
        i8* err_bb_s = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_s, "ts_err");
        i8* ok_bb_s  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_s, "ts_ok");
        LLVMBuildCondBr(ctx.llvm_builder, is_err_s, err_bb_s, ok_bb_s);
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, err_bb_s);
        i32 ts_di = ctx.defers.len - 1;
        while (ts_di >= 0) {
            emit_deferred(&ctx.defers.data[ts_di], ctx);
            ts_di = ts_di - 1;
        }
        i32 ts_ei = ctx.errdefers.len - 1;
        while (ts_ei >= 0) {
            emit_deferred(&ctx.errdefers.data[ts_ei], ctx);
            ts_ei = ts_ei - 1;
        }
        i8* ts_ret = ctx.current_ret_type != (i8*)0 ? ctx.current_ret_type : i32_t_s;
        LLVMBuildRet(ctx.llvm_builder, coerce_int_val(neg1_s, ts_ret, ctx.llvm_builder));
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, ok_bb_s);
        return;
    }
    // Inline type declarations inside a function body (e.g., anonymous istruc per-instance init).
    // Forward to the top-level declaration visitor which registers the type in ctx.struct_types.
    if (kind == nd_namespace_decl || kind == nd_struct_decl || kind == nd_enum_decl || kind == nd_typedef_decl) {
        visit_top_level_decl(node, ctx);
        return;
    }
    // Other statement kinds ignored silently.
}

} // namespace ir
