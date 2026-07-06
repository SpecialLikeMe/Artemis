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
    ctx->push_errdefer_scope();
    for (auto* s : blk->stmts) {
        if (ctx->is_terminated()) break; // dead code after a terminator
        visit_stmt(s, ctx);
    }
    // Emit deferred items at end of block (fall-through path only).
    // errdeferred items are discarded here — they are emitted only on error exit paths.
    auto deferred = ctx->pop_defer_scope();
    ctx->pop_errdefer_scope();
    if (!ctx->is_terminated()) emit_deferred(deferred, ctx);
    ctx->pop_scope();
}

// ------------------------------------------------------------------ local variable declaration

inline void visit_local_var_decl(var_decl* d, ir_context* ctx) {
    // sta-typed variables are comptime-only (namespaces / types); no runtime representation.
    if (d->is_sta || (d->type && d->type->is_sta)) return;

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
        // For istruc class types with = expr (not () or {}): store raw; operator= is called
        // after the zero-arg ctor below. Raw store here initialises memory so the ctor
        // (if any) has a valid object to work on, and operator= runs last.
        LLVMBuildStore(ctx->llvm_builder, init_val, alloca);
    } else {
        // char* (i8*, u8*, char*) without a nullable flag defaults to a writable empty string
        // rather than null — the user must use ?char* to get a nullable pointer.
        bool is_char_star = d->type && d->type->is_primitive && d->type->pointer_depth == 1
            && !d->type->is_nullable
            && (d->type->prim == prim_type_t::char_t
                || (d->type->prim == prim_type_t::arb_int  && d->type->bit_width == 8)
                || (d->type->prim == prim_type_t::arb_uint && d->type->bit_width == 8));
        if (is_char_star) {
            LLVMTypeRef i8t = LLVMInt8TypeInContext(ctx->llvm_ctx);
            LLVMValueRef buf = LLVMBuildAlloca(ctx->llvm_builder, i8t, "empty_str");
            LLVMBuildStore(ctx->llvm_builder, LLVMConstInt(i8t, 0, 0), buf);
            LLVMBuildStore(ctx->llvm_builder, buf, alloca);
        } else {
            LLVMBuildStore(ctx->llvm_builder, LLVMConstNull(alloca_t), alloca);
        }
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
            // If param count doesn't match, try overloaded versions (__OL1, __OL2, ...)
            if (explicit_call) {
                unsigned needed = 1 + (unsigned)d->ctor_args.size();
                if (nparams != needed) {
                    std::string base_cn = LLVMGetStructName(alloca_t)
                                         ? LLVMGetStructName(alloca_t) : *d->type->name;
                    std::string base_ctor = base_cn + "__MT___construct__";
                    for (int oi = 1; oi <= 16; oi++) {
                        std::string oln = base_ctor + "__OL" + std::to_string(oi);
                        auto cit2 = ctx->global_funcs.find(oln);
                        if (cit2 == ctx->global_funcs.end()) break;
                        LLVMTypeRef oft = ctx->global_func_types[oln];
                        if (LLVMCountParamTypes(oft) == needed) {
                            ctor_fn = cit2->second;
                            ctor_ft = oft;
                            nparams = needed;
                            break;
                        }
                    }
                }
            }
            // Auto-call only a no-arg (self-only) constructor when no explicit (...) given.
            if (explicit_call || nparams == 1) {
                std::vector<LLVMValueRef> cargs = { alloca };
                std::vector<LLVMTypeRef> pts(nparams);
                if (nparams) LLVMGetParamTypes(ctor_ft, pts.data());
                for (size_t i = 0; i < d->ctor_args.size(); ++i) {
                    size_t pi = i + 1;
                    // Coerce concrete struct to &memstr fat pointer if needed
                    if (ctx->memstr_fat_type && pi < nparams && pts[pi] == ctx->memstr_fat_type) {
                        LLVMTypeRef arg_elem = (d->ctor_args[i]->kind == expr_kind::identifier)
                            ? ctx->lookup_local_type(d->ctor_args[i]->str_val) : nullptr;
                        const char* sn = (arg_elem && LLVMGetTypeKind(arg_elem) == LLVMStructTypeKind)
                            ? LLVMGetStructName(arg_elem) : nullptr;
                        auto vit = sn ? ctx->memstr_vtables.find(sn) : ctx->memstr_vtables.end();
                        if (vit != ctx->memstr_vtables.end()) {
                            LLVMValueRef struct_addr = visit_lvalue(d->ctor_args[i], ctx);
                            LLVMValueRef fat = LLVMGetUndef(ctx->memstr_fat_type);
                            fat = LLVMBuildInsertValue(ctx->llvm_builder, fat, struct_addr,  0, "fd");
                            fat = LLVMBuildInsertValue(ctx->llvm_builder, fat, vit->second,  1, "fv");
                            cargs.push_back(fat);
                            continue;
                        }
                    }
                    LLVMValueRef av = visit_expr(d->ctor_args[i], ctx);
                    if (pi < nparams) av = coerce_int_val(av, pts[pi], ctx->llvm_builder);
                    cargs.push_back(av);
                }
                LLVMBuildCall2(ctx->llvm_builder, ctor_ft, ctor_fn,
                               cargs.data(), static_cast<unsigned>(cargs.size()), "");
            }
        }
    }

    // For class types initialised with `= expr` (not a ctor call, not a class_init):
    // call operator= if one exists. This runs after the zero-arg ctor so the object
    // is fully initialised before assignment.
    if (d->init.has_value() && !d->has_ctor_parens && d->ctor_args.empty()
        && d->init.value()->kind != expr_kind::class_init
        && d->type && !d->type->is_primitive && d->type->name && d->type->pointer_depth == 0
        && LLVMGetTypeKind(alloca_t) == LLVMStructTypeKind) {
        const char* sn = LLVMGetStructName(alloca_t);
        if (sn && ctx->class_infos.count(sn)) {
            std::string op_name = std::string(sn) + "__MT_operator=";
            auto fit = ctx->global_funcs.find(op_name);
            if (fit != ctx->global_funcs.end()) {
                LLVMTypeRef op_ft = ctx->global_func_types[op_name];
                LLVMValueRef init_val = visit_expr(d->init.value(), ctx);
                LLVMValueRef mt_args[2] = { alloca, init_val };
                LLVMBuildCall2(ctx->llvm_builder, op_ft, fit->second, mt_args, 2, "");
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
    LLVMValueRef raw_cond_val = cond_val; // preserve for capture binding (pre-normalization)

    // constexpr if: if the condition folds to a compile-time constant, emit only the
    // taken branch and discard the other entirely (compile-time branch elimination).
    if (s->is_constexpr && LLVMIsConstant(cond_val)
        && LLVMGetTypeKind(LLVMTypeOf(cond_val)) == LLVMIntegerTypeKind) {
        bool taken = LLVMConstIntGetZExtValue(cond_val) != 0;
        if (taken)             visit_stmt(s->then_body, ctx);
        else if (s->else_body) visit_stmt(s->else_body, ctx);
        return;
    }

    // Normalise any non-i1 condition to i1 (only the branch condition, not the capture).
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

    // Emit then branch (with optional capture variable).
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, then_bb);
    ctx->push_scope();
    if (s->then_capture.has_value()) {
        LLVMTypeRef  raw_t = LLVMTypeOf(raw_cond_val);
        LLVMValueRef cap   = LLVMBuildAlloca(ctx->llvm_builder, raw_t, s->then_capture->c_str());
        LLVMBuildStore(ctx->llvm_builder, raw_cond_val, cap);
        ctx->declare_local(*s->then_capture, cap, raw_t);
    }
    visit_stmt(s->then_body, ctx);
    ctx->pop_scope();
    if (!ctx->is_terminated()) LLVMBuildBr(ctx->llvm_builder, merge_bb);

    // Emit else branch (optional, with optional capture variable).
    if (else_bb) {
        LLVMPositionBuilderAtEnd(ctx->llvm_builder, else_bb);
        ctx->push_scope();
        if (s->else_capture.has_value()) {
            LLVMTypeRef  raw_t = LLVMTypeOf(raw_cond_val);
            LLVMValueRef cap   = LLVMBuildAlloca(ctx->llvm_builder, raw_t, s->else_capture->c_str());
            LLVMBuildStore(ctx->llvm_builder, raw_cond_val, cap);
            ctx->declare_local(*s->else_capture, cap, raw_t);
        }
        visit_stmt(s->else_body, ctx);
        ctx->pop_scope();
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
    LLVMTypeRef i64t = LLVMInt64TypeInContext(ctx->llvm_ctx);

    LLVMValueRef count_val = nullptr;

    // Case 1: static array with known compile-time size
    if (s->range && s->range->cast_type && s->range->cast_type->array_size.has_value()) {
        count_val = visit_expr(s->range->cast_type->array_size.value(), ctx);
    }

    // Case 2: struct value with a "length" field (e.g. std::vector<T>)
    if (!count_val && s->range && s->range->cast_type && !s->range->cast_type->is_primitive
        && s->range->cast_type->name.has_value() && s->range->cast_type->pointer_depth == 0) {
        const std::string& sname = *s->range->cast_type->name;
        auto nit = ctx->struct_field_names.find(sname);
        auto tit = ctx->struct_field_types.find(sname);
        if (nit != ctx->struct_field_names.end() && tit != ctx->struct_field_types.end()) {
            const auto& fnames = nit->second;
            const auto& ftypes = tit->second;
            // Find "length" field for the count
            for (unsigned fi = 0; fi < fnames.size(); fi++) {
                if (fnames[fi] == "length" || fnames[fi] == "size") {
                    count_val = LLVMBuildExtractValue(ctx->llvm_builder, range_val, fi, "range_len");
                    break;
                }
            }
            // Find first pointer field for the data pointer
            for (unsigned fi = 0; fi < ftypes.size(); fi++) {
                if (LLVMGetTypeKind(ftypes[fi]) == LLVMPointerTypeKind) {
                    range_val = LLVMBuildExtractValue(ctx->llvm_builder, range_val, fi, "range_data");
                    break;
                }
            }
        }
    }

    // Case 3: pointer to struct — dereference then look for "length" field
    if (!count_val && s->range && s->range->cast_type && !s->range->cast_type->is_primitive
        && s->range->cast_type->name.has_value() && s->range->cast_type->pointer_depth == 1) {
        const std::string& sname = *s->range->cast_type->name;
        auto nit = ctx->struct_field_names.find(sname);
        auto tit = ctx->struct_field_types.find(sname);
        if (nit != ctx->struct_field_names.end() && tit != ctx->struct_field_types.end()) {
            const auto& fnames = nit->second;
            const auto& ftypes = tit->second;
            // Build the struct LLVM type to GEP into the pointer
            LLVMTypeRef struct_t = nullptr;
            auto sit = ctx->struct_types.find(sname);
            if (sit != ctx->struct_types.end()) struct_t = sit->second;
            if (struct_t) {
                for (unsigned fi = 0; fi < fnames.size(); fi++) {
                    if (fnames[fi] == "length" || fnames[fi] == "size") {
                        LLVMValueRef gep = LLVMBuildStructGEP2(ctx->llvm_builder, struct_t, range_val, fi, "len_ptr");
                        count_val = LLVMBuildLoad2(ctx->llvm_builder, ftypes[fi], gep, "range_len");
                        break;
                    }
                }
                for (unsigned fi = 0; fi < ftypes.size(); fi++) {
                    if (LLVMGetTypeKind(ftypes[fi]) == LLVMPointerTypeKind) {
                        LLVMValueRef gep = LLVMBuildStructGEP2(ctx->llvm_builder, struct_t, range_val, fi, "data_ptr");
                        range_val = LLVMBuildLoad2(ctx->llvm_builder, ftypes[fi], gep, "range_data");
                        break;
                    }
                }
            }
        }
    }

    // Case 4: plain identifier range with no cast_type — infer struct from local variable type
    if (!count_val && s->range && s->range->kind == expr_kind::identifier) {
        LLVMTypeRef lt = ctx->lookup_local_type(s->range->str_val);
        if (lt && LLVMGetTypeKind(lt) == LLVMStructTypeKind) {
            const char* sn = LLVMGetStructName(lt);
            std::string sname = sn ? sn : "";
            auto nit = ctx->struct_field_names.find(sname);
            auto tit = ctx->struct_field_types.find(sname);
            if (nit != ctx->struct_field_names.end() && tit != ctx->struct_field_types.end()) {
                const auto& fnames = nit->second;
                const auto& ftypes = tit->second;
                for (unsigned fi = 0; fi < fnames.size(); fi++) {
                    if (fnames[fi] == "length" || fnames[fi] == "size") {
                        count_val = LLVMBuildExtractValue(ctx->llvm_builder, range_val, fi, "range_len");
                        break;
                    }
                }
                for (unsigned fi = 0; fi < ftypes.size(); fi++) {
                    if (LLVMGetTypeKind(ftypes[fi]) == LLVMPointerTypeKind) {
                        range_val = LLVMBuildExtractValue(ctx->llvm_builder, range_val, fi, "range_data");
                        break;
                    }
                }
            }
        }
    }

    if (!count_val) {
        // No count derivable — zero-iteration safe fallback
        count_val = LLVMConstInt(i64t, 0, 0);
    }
    count_val = LLVMBuildIntCast2(ctx->llvm_builder, count_val, i64t, 0, "range_count");

    // Allocate the index variable.
    LLVMValueRef idx_alloca = LLVMBuildAlloca(ctx->llvm_builder, i64t, "range_idx");
    LLVMBuildStore(ctx->llvm_builder, LLVMConstInt(i64t, 0, 0), idx_alloca);

    // Allocate the element variable that the body uses.
    LLVMValueRef elem_alloca = LLVMBuildAlloca(ctx->llvm_builder, elem_llvm_t, s->var_name.c_str());

    LLVMBuildBr(ctx->llvm_builder, cond_bb);

    // Condition: idx < count
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, cond_bb);
    LLVMValueRef idx_cur = LLVMBuildLoad2(ctx->llvm_builder, i64t, idx_alloca, "idx");
    LLVMValueRef cond_v  = LLVMBuildICmp(ctx->llvm_builder, LLVMIntULT, idx_cur, count_val, "range_lt");
    LLVMBuildCondBr(ctx->llvm_builder, cond_v, body_bb, exit_bb);

    // Body: load base_ptr[idx] into elem, then run body.
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, body_bb);
    ctx->push_scope();
    LLVMValueRef elem_ptr = LLVMBuildGEP2(ctx->llvm_builder, elem_llvm_t, range_val, &idx_cur, 1, "elem_ptr");
    LLVMValueRef elem_val = LLVMBuildLoad2(ctx->llvm_builder, elem_llvm_t, elem_ptr, "elem");
    LLVMBuildStore(ctx->llvm_builder, elem_val, elem_alloca);

    ctx->declare_local(s->var_name, elem_alloca, elem_llvm_t, nullptr, false);

    ctx->push_loop(exit_bb, step_bb);
    visit_stmt(s->body, ctx);
    ctx->pop_loop();
    if (!ctx->is_terminated()) LLVMBuildBr(ctx->llvm_builder, step_bb);
    ctx->pop_scope();

    // Step: idx++
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, step_bb);
    LLVMValueRef idx_new = LLVMBuildAdd(ctx->llvm_builder, idx_cur, LLVMConstInt(i64t, 1, 0), "idx_inc");
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

inline void visit_errdefer_stmt(errdefer_stmt* s, ir_context* ctx) {
    // Register in the errdefer scope; emitted only on error-path exits (return error.X or try).
    if (s->blk)       ctx->add_errdefer(static_cast<void*>(s->blk),  true);
    else if (s->expr) ctx->add_errdefer(static_cast<void*>(s->expr), false);
}

// ------------------------------------------------------------------ return

inline void visit_return_stmt(return_stmt* s, ir_context* ctx) {
    // Determine whether this is an error return before emitting anything
    bool is_error_return = false;
    if (ctx->current_func_is_error_union && s->value.has_value())
        is_error_return = (s->value.value()->kind == expr_kind::error_lit);

    // On error exit: fire errdeferred items first (LIFO across all scopes)
    if (is_error_return) {
        std::vector<std::vector<std::pair<void*, bool>>> all_errdeferred;
        for (auto& scope_items : ctx->errdefer_stack)
            all_errdeferred.push_back(scope_items);
        for (auto it = all_errdeferred.rbegin(); it != all_errdeferred.rend(); ++it)
            emit_deferred(*it, ctx);
    }

    // Emit ALL regular deferred items (all scopes) before returning
    std::vector<std::vector<std::pair<void*, bool>>> all_deferred;
    for (auto& scope_items : ctx->defer_stack)
        all_deferred.push_back(scope_items);
    for (auto it = all_deferred.rbegin(); it != all_deferred.rend(); ++it)
        emit_deferred(*it, ctx);

    LLVMTypeRef i32t = LLVMInt32TypeInContext(ctx->llvm_ctx);

    if (ctx->current_func_is_error_union) {
        LLVMTypeRef eu_t   = ctx->current_error_union_type;
        LLVMTypeRef i8pt   = LLVMPointerType(LLVMInt8TypeInContext(ctx->llvm_ctx), 0);
        bool is_void_union = eu_t && LLVMGetTypeKind(eu_t) == LLVMStructTypeKind
                             && LLVMCountStructElementTypes(eu_t) == 2;

        if (!s->value.has_value()) {
            // Implicit success: {0, null} for !void or {0, null, undef} for !T
            if (!eu_t) {
                LLVMBuildRetVoid(ctx->llvm_builder);
            } else {
                LLVMValueRef eu = LLVMGetUndef(eu_t);
                eu = LLVMBuildInsertValue(ctx->llvm_builder, eu, LLVMConstInt(i32t, 0, 0), 0, "eu_ok_tag");
                eu = LLVMBuildInsertValue(ctx->llvm_builder, eu, LLVMConstNull(i8pt), 1, "eu_ok_payload");
                LLVMBuildRet(ctx->llvm_builder, eu);
            }
            return;
        }

        expr_node* ret_expr = s->value.value();
        bool is_error = (ret_expr->kind == expr_kind::error_lit);

        if (is_error) {
            // error.Name or error.Name(expr) — emit tag and optional payload
            LLVMValueRef tag_val = visit_expr(ret_expr, ctx);  // i32 hash from visit_error_lit_expr
            LLVMValueRef payload = LLVMConstNull(i8pt);
            if (ret_expr->operand) {
                // error.Name(expr) — cast payload to i8*
                LLVMValueRef pv = visit_expr(ret_expr->operand, ctx);
                LLVMTypeRef  pt = LLVMTypeOf(pv);
                if (LLVMGetTypeKind(pt) == LLVMPointerTypeKind) {
                    payload = LLVMBuildBitCast(ctx->llvm_builder, pv, i8pt, "eu_payload");
                } else {
                    // Store integer payload in a global and take its address
                    LLVMValueRef pg = LLVMAddGlobal(ctx->llvm_mod, pt, ".err_payload");
                    LLVMSetInitializer(pg, LLVMConstNull(pt));
                    LLVMSetLinkage(pg, LLVMPrivateLinkage);
                    LLVMBuildStore(ctx->llvm_builder, pv, pg);
                    payload = LLVMBuildBitCast(ctx->llvm_builder, pg, i8pt, "eu_payload");
                }
            }
            if (eu_t) {
                LLVMValueRef eu = LLVMGetUndef(eu_t);
                eu = LLVMBuildInsertValue(ctx->llvm_builder, eu, tag_val, 0, "eu_err_tag");
                eu = LLVMBuildInsertValue(ctx->llvm_builder, eu, payload, 1, "eu_err_payload");
                LLVMBuildRet(ctx->llvm_builder, eu);
            } else {
                LLVMBuildRet(ctx->llvm_builder, tag_val);
            }
        } else {
            // Success value return: {0, null, value}
            LLVMValueRef val = visit_expr(ret_expr, ctx);
            if (!eu_t) {
                LLVMBuildRet(ctx->llvm_builder, val);
            } else if (is_void_union) {
                // !void — just return {0, null}
                LLVMValueRef eu = LLVMGetUndef(eu_t);
                eu = LLVMBuildInsertValue(ctx->llvm_builder, eu, LLVMConstInt(i32t, 0, 0), 0, "eu_ok_tag");
                eu = LLVMBuildInsertValue(ctx->llvm_builder, eu, LLVMConstNull(i8pt), 1, "eu_ok_payload");
                LLVMBuildRet(ctx->llvm_builder, eu);
            } else {
                // !T — wrap as {0, null, value}
                LLVMTypeRef ok_t = LLVMStructGetTypeAtIndex(eu_t, 2);
                val = coerce_int_val(val, ok_t, ctx->llvm_builder);
                LLVMValueRef eu = LLVMGetUndef(eu_t);
                eu = LLVMBuildInsertValue(ctx->llvm_builder, eu, LLVMConstInt(i32t, 0, 0), 0, "eu_ok_tag");
                eu = LLVMBuildInsertValue(ctx->llvm_builder, eu, LLVMConstNull(i8pt), 1, "eu_ok_payload");
                eu = LLVMBuildInsertValue(ctx->llvm_builder, eu, val, 2, "eu_ok_val");
                LLVMBuildRet(ctx->llvm_builder, eu);
            }
        }
        return;
    }

    if (!s->value.has_value()) {
        LLVMBuildRetVoid(ctx->llvm_builder);
        return;
    }
    LLVMValueRef val = visit_expr(s->value.value(), ctx);
    LLVMTypeRef fn_t  = LLVMGlobalGetValueType(ctx->current_func);
    LLVMTypeRef ret_t = LLVMGetReturnType(fn_t);
    if (LLVMGetTypeKind(ret_t) == LLVMPointerTypeKind &&
        LLVMGetTypeKind(LLVMTypeOf(val)) == LLVMIntegerTypeKind)
        val = LLVMBuildIntToPtr(ctx->llvm_builder, val, ret_t, "nullcast");
    else
        val = coerce_int_val(val, ret_t, ctx->llvm_builder);
    LLVMBuildRet(ctx->llvm_builder, val);
}

// ------------------------------------------------------------------ try expr statement

inline void visit_try_expr_stmt(try_expr_stmt* s, ir_context* ctx) {
    if (!s->expr) return;
    LLVMValueRef result   = visit_expr(s->expr, ctx);
    LLVMTypeRef  result_t = LLVMTypeOf(result);
    LLVMTypeRef  i32t     = LLVMInt32TypeInContext(ctx->llvm_ctx);
    if (LLVMGetTypeKind(result_t) != LLVMStructTypeKind ||
        LLVMCountStructElementTypes(result_t) < 1)
        return; // not an error-union; nothing to propagate

    LLVMValueRef err_tag = LLVMBuildExtractValue(ctx->llvm_builder, result, 0, "eu_tag");
    LLVMValueRef is_err  = LLVMBuildICmp(ctx->llvm_builder, LLVMIntNE,
                                          err_tag, LLVMConstInt(i32t, 0, 0), "is_err");
    LLVMValueRef fn      = ctx->current_func;
    LLVMBasicBlockRef err_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "try_err");
    LLVMBasicBlockRef ok_bb  = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "try_ok");
    LLVMBuildCondBr(ctx->llvm_builder, is_err, err_bb, ok_bb);

    LLVMPositionBuilderAtEnd(ctx->llvm_builder, err_bb);
    if (ctx->current_func_is_error_union && ctx->current_error_union_type) {
        // Error propagation — fire errdeferred items then regular deferred items
        std::vector<std::vector<std::pair<void*, bool>>> all_errdeferred;
        for (auto& scope_items : ctx->errdefer_stack)
            all_errdeferred.push_back(scope_items);
        for (auto it = all_errdeferred.rbegin(); it != all_errdeferred.rend(); ++it)
            emit_deferred(*it, ctx);
        std::vector<std::vector<std::pair<void*, bool>>> all_deferred;
        for (auto& scope_items : ctx->defer_stack)
            all_deferred.push_back(scope_items);
        for (auto it = all_deferred.rbegin(); it != all_deferred.rend(); ++it)
            emit_deferred(*it, ctx);

        LLVMTypeRef outer_t = ctx->current_error_union_type;
        LLVMTypeRef i8pt    = LLVMPointerType(LLVMInt8TypeInContext(ctx->llvm_ctx), 0);
        if (LLVMGetTypeKind(outer_t) == LLVMStructTypeKind) {
            LLVMValueRef payload = LLVMCountStructElementTypes(result_t) >= 2
                ? LLVMBuildExtractValue(ctx->llvm_builder, result, 1, "eu_payload")
                : LLVMConstNull(i8pt);
            LLVMValueRef eu = LLVMGetUndef(outer_t);
            eu = LLVMBuildInsertValue(ctx->llvm_builder, eu, err_tag, 0, "eu_prop_tag");
            if (LLVMCountStructElementTypes(outer_t) >= 2)
                eu = LLVMBuildInsertValue(ctx->llvm_builder, eu, payload, 1, "eu_prop_payload");
            LLVMBuildRet(ctx->llvm_builder, eu);
        } else {
            LLVMBuildRet(ctx->llvm_builder, err_tag);
        }
    } else {
        LLVMBuildUnreachable(ctx->llvm_builder);
    }
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, ok_bb);
    // Success value is discarded (statement context)
}

// ------------------------------------------------------------------ res block statement
// res { stmts } acts as a local scope that can return an error or a value.
// Errors raised inside (via `error.X` as a statement expr) propagate to the caller
// when wrapped with `try res { }`, or are caught with `res { } except |e| {}`.
// The last expression in the block is the block's success value.

inline void visit_res_block_stmt(res_block_stmt* s, ir_context* ctx) {
    if (!s->body) return;
    // res blocks compile identically to plain blocks; try/except on the enclosing
    // expression handle error capture. The distinction is at parse/analyzer level.
    ctx->push_scope();
    visit_block_stmt(s->body, ctx);
    ctx->pop_scope();
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
    if (auto* n = dynamic_cast<asm_stmt*>(node))        { visit_asm_stmt(n, ctx);        return; }
    if (auto* n = dynamic_cast<defer_stmt*>(node))      { visit_defer_stmt(n, ctx);      return; }
    if (auto* n = dynamic_cast<errdefer_stmt*>(node))   { visit_errdefer_stmt(n, ctx);   return; }
    if (auto* n = dynamic_cast<try_expr_stmt*>(node))   { visit_try_expr_stmt(n, ctx);   return; }
    if (auto* n = dynamic_cast<res_block_stmt*>(node))  { visit_res_block_stmt(n, ctx);  return; }

    throw std::runtime_error("IR: Unknown statement kind in visit_stmt");
}
