#pragma once
#include "types.hxx"

// Forward declare the dispatcher so recursive expressions compile.
inline LLVMValueRef visit_expr(expr_node* e, ir_context* ctx);
// Forward declare lvalue helper used by assign/unary addr_of.
inline LLVMValueRef visit_lvalue(expr_node* e, ir_context* ctx);

// ------------------------------------------------------------------ literals

inline LLVMValueRef visit_int_lit(expr_node* e, ir_context* ctx) {
    LLVMTypeRef i32 = LLVMInt32TypeInContext(ctx->llvm_ctx);
    return LLVMConstInt(i32, static_cast<unsigned long long>(e->int_val), /*sign-extend=*/1);
}

inline LLVMValueRef visit_float_lit(expr_node* e, ir_context* ctx) {
    LLVMTypeRef f64 = LLVMDoubleTypeInContext(ctx->llvm_ctx);
    return LLVMConstReal(f64, e->flt_val);
}

inline LLVMValueRef visit_string_lit(expr_node* e, ir_context* ctx) {
    // Creates a null-terminated global string constant and returns a u8* pointer to it.
    return LLVMBuildGlobalStringPtr(ctx->llvm_builder,
                                    e->str_val.c_str(), "str");
}

inline LLVMValueRef visit_char_lit(expr_node* e, ir_context* ctx) {
    LLVMTypeRef i8 = LLVMInt8TypeInContext(ctx->llvm_ctx);
    unsigned char c = e->str_val.empty() ? 0 : static_cast<unsigned char>(e->str_val[0]);
    return LLVMConstInt(i8, c, /*sign-extend=*/0);
}

inline LLVMValueRef visit_bool_lit(expr_node* e, ir_context* ctx) {
    LLVMTypeRef i1 = LLVMInt1TypeInContext(ctx->llvm_ctx);
    return LLVMConstInt(i1, e->bool_val ? 1 : 0, /*sign-extend=*/0);
}

// ------------------------------------------------------------------ identifier

inline LLVMValueRef visit_identifier_expr(expr_node* e, ir_context* ctx) {
    // Local variable: load from alloca.
    LLVMValueRef ptr  = ctx->lookup_local(e->str_val);
    LLVMTypeRef  type = ctx->lookup_local_type(e->str_val);
    if (ptr && type)
        return LLVMBuildLoad2(ctx->llvm_builder, type, ptr, e->str_val.c_str());

    // Global variable: load from global.
    auto git = ctx->global_vars.find(e->str_val);
    if (git != ctx->global_vars.end()) {
        LLVMTypeRef gt = LLVMGlobalGetValueType(git->second);
        return LLVMBuildLoad2(ctx->llvm_builder, gt, git->second, e->str_val.c_str());
    }

    // Function reference (when used as a value, e.g. for function pointers).
    auto fit = ctx->global_funcs.find(e->str_val);
    if (fit != ctx->global_funcs.end())
        return fit->second;

    throw std::runtime_error("IR: Unknown identifier '" + e->str_val + "'");
}

// ------------------------------------------------------------------ lvalue address

// Returns the alloca/GEP pointer for an assignable location (does NOT load).
inline LLVMValueRef visit_lvalue(expr_node* e, ir_context* ctx) {
    switch (e->kind) {
        case expr_kind::identifier: {
            LLVMValueRef ptr = ctx->lookup_local(e->str_val);
            if (ptr) return ptr;
            auto git = ctx->global_vars.find(e->str_val);
            if (git != ctx->global_vars.end()) return git->second;
            throw std::runtime_error("IR: Unknown lvalue '" + e->str_val + "'");
        }
        case expr_kind::unary:
            // *ptr  -> the pointer value itself is the address
            return visit_expr(e->operand, ctx);

        case expr_kind::subscript: {
            LLVMValueRef base_ptr = visit_lvalue(e->object, ctx);
            LLVMValueRef idx      = visit_expr(e->index, ctx);
            LLVMTypeRef  elem_t   = ctx->lookup_local_type(e->object->str_val);
            if (!elem_t) elem_t = LLVMInt8TypeInContext(ctx->llvm_ctx);
            return LLVMBuildGEP2(ctx->llvm_builder, elem_t, base_ptr, &idx, 1, "elemptr");
        }
        case expr_kind::member: {
            // GEP into a struct.
            LLVMValueRef struct_ptr = visit_lvalue(e->object, ctx);
            // Look up the struct type from object's identifier name (best-effort).
            std::string tname;
            if (e->object->kind == expr_kind::identifier) {
                LLVMTypeRef elem = ctx->lookup_local_type(e->object->str_val);
                if (elem) tname = LLVMGetStructName(elem) ? LLVMGetStructName(elem) : "";
            }
            auto fit = ctx->struct_field_names.find(tname);
            if (fit == ctx->struct_field_names.end())
                throw std::runtime_error("IR: Struct '" + tname + "' not registered");
            const auto& fields = fit->second;
            for (unsigned i = 0; i < fields.size(); i++) {
                if (fields[i] == e->member_name) {
                    LLVMTypeRef struct_t = ctx->struct_types[tname];
                    LLVMValueRef indices[2] = {
                        LLVMConstInt(LLVMInt32TypeInContext(ctx->llvm_ctx), 0, 0),
                        LLVMConstInt(LLVMInt32TypeInContext(ctx->llvm_ctx), i, 0)
                    };
                    return LLVMBuildGEP2(ctx->llvm_builder, struct_t, struct_ptr, indices, 2, "fieldptr");
                }
            }
            throw std::runtime_error("IR: No field '" + e->member_name + "' in struct '" + tname + "'");
        }
        default:
            throw std::runtime_error("IR: Expression is not an lvalue");
    }
}

// ------------------------------------------------------------------ unary

inline LLVMValueRef visit_unary_expr(expr_node* e, ir_context* ctx) {
    uint64_t ln = e->line;

    switch (e->uop) {
        case unary_op::neg: {
            LLVMValueRef v = visit_expr(e->operand, ctx);
            return llvm_is_float(LLVMTypeOf(v))
                ? LLVMBuildFNeg(ctx->llvm_builder, v, "negtmp")
                : LLVMBuildNeg(ctx->llvm_builder,  v, "negtmp");
        }
        case unary_op::pos:
            return visit_expr(e->operand, ctx);

        case unary_op::bit_not:
            return LLVMBuildNot(ctx->llvm_builder, visit_expr(e->operand, ctx), "bnottmp");

        case unary_op::log_not: {
            LLVMValueRef v  = visit_expr(e->operand, ctx);
            LLVMValueRef z  = LLVMConstNull(LLVMTypeOf(v));
            LLVMTypeRef  i1 = LLVMInt1TypeInContext(ctx->llvm_ctx);
            LLVMValueRef cmp = llvm_is_float(LLVMTypeOf(v))
                ? LLVMBuildFCmp(ctx->llvm_builder, LLVMRealOEQ, v, z, "lnottmp")
                : LLVMBuildICmp(ctx->llvm_builder, LLVMIntEQ,   v, z, "lnottmp");
            return LLVMBuildZExt(ctx->llvm_builder, cmp, i1, "lnot_i1");
        }
        case unary_op::pre_inc: {
            LLVMValueRef ptr = visit_lvalue(e->operand, ctx);
            LLVMTypeRef  t   = ctx->lookup_local_type(e->operand->str_val);
            if (!t) t = LLVMInt32TypeInContext(ctx->llvm_ctx);
            LLVMValueRef old = LLVMBuildLoad2(ctx->llvm_builder, t, ptr, "preinc_old");
            LLVMValueRef one = LLVMConstInt(t, 1, 0);
            LLVMValueRef inc = LLVMBuildAdd(ctx->llvm_builder, old, one, "preinc");
            LLVMBuildStore(ctx->llvm_builder, inc, ptr);
            return inc;
        }
        case unary_op::pre_dec: {
            LLVMValueRef ptr = visit_lvalue(e->operand, ctx);
            LLVMTypeRef  t   = ctx->lookup_local_type(e->operand->str_val);
            if (!t) t = LLVMInt32TypeInContext(ctx->llvm_ctx);
            LLVMValueRef old = LLVMBuildLoad2(ctx->llvm_builder, t, ptr, "predec_old");
            LLVMValueRef one = LLVMConstInt(t, 1, 0);
            LLVMValueRef dec = LLVMBuildSub(ctx->llvm_builder, old, one, "predec");
            LLVMBuildStore(ctx->llvm_builder, dec, ptr);
            return dec;
        }
        case unary_op::post_inc: {
            LLVMValueRef ptr = visit_lvalue(e->operand, ctx);
            LLVMTypeRef  t   = ctx->lookup_local_type(e->operand->str_val);
            if (!t) t = LLVMInt32TypeInContext(ctx->llvm_ctx);
            LLVMValueRef old = LLVMBuildLoad2(ctx->llvm_builder, t, ptr, "postinc_old");
            LLVMValueRef one = LLVMConstInt(t, 1, 0);
            LLVMBuildStore(ctx->llvm_builder, LLVMBuildAdd(ctx->llvm_builder, old, one, "postinc"), ptr);
            return old; // post-increment returns the value before increment
        }
        case unary_op::post_dec: {
            LLVMValueRef ptr = visit_lvalue(e->operand, ctx);
            LLVMTypeRef  t   = ctx->lookup_local_type(e->operand->str_val);
            if (!t) t = LLVMInt32TypeInContext(ctx->llvm_ctx);
            LLVMValueRef old = LLVMBuildLoad2(ctx->llvm_builder, t, ptr, "postdec_old");
            LLVMValueRef one = LLVMConstInt(t, 1, 0);
            LLVMBuildStore(ctx->llvm_builder, LLVMBuildSub(ctx->llvm_builder, old, one, "postdec"), ptr);
            return old;
        }
        case unary_op::deref: {
            LLVMValueRef ptr = visit_expr(e->operand, ctx);
            // Look up the pointed-to type tracked at declaration time; fall back to i8.
            LLVMTypeRef elem_t = LLVMInt8TypeInContext(ctx->llvm_ctx);
            if (e->operand->kind == expr_kind::identifier) {
                LLVMTypeRef dt = ctx->lookup_deref_type(e->operand->str_val);
                if (dt) elem_t = dt;
            }
            return LLVMBuildLoad2(ctx->llvm_builder, elem_t, ptr, "dereftmp");
        }
        case unary_op::addr_of:
            return visit_lvalue(e->operand, ctx);

        default:
            throw std::runtime_error("IR: Unknown unary operator at line " + std::to_string(ln));
    }
}

// ------------------------------------------------------------------ binary

// Short-circuit && — evaluates rhs only when lhs is truthy.
inline LLVMValueRef visit_log_and(expr_node* e, ir_context* ctx) {
    LLVMTypeRef  i1   = LLVMInt1TypeInContext(ctx->llvm_ctx);
    LLVMValueRef fn   = ctx->current_func;

    LLVMBasicBlockRef rhs_bb   = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "land_rhs");
    LLVMBasicBlockRef merge_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "land_merge");

    LLVMValueRef lv   = visit_expr(e->lhs, ctx);
    LLVMValueRef l_b  = LLVMBuildICmp(ctx->llvm_builder, LLVMIntNE, lv, LLVMConstNull(LLVMTypeOf(lv)), "land_lhs_bool");
    LLVMBasicBlockRef lhs_exit = LLVMGetInsertBlock(ctx->llvm_builder);
    LLVMBuildCondBr(ctx->llvm_builder, l_b, rhs_bb, merge_bb);

    LLVMPositionBuilderAtEnd(ctx->llvm_builder, rhs_bb);
    LLVMValueRef rv  = visit_expr(e->rhs, ctx);
    LLVMValueRef r_b = LLVMBuildICmp(ctx->llvm_builder, LLVMIntNE, rv, LLVMConstNull(LLVMTypeOf(rv)), "land_rhs_bool");
    LLVMBasicBlockRef rhs_exit = LLVMGetInsertBlock(ctx->llvm_builder);
    LLVMBuildBr(ctx->llvm_builder, merge_bb);

    LLVMPositionBuilderAtEnd(ctx->llvm_builder, merge_bb);
    LLVMValueRef phi = LLVMBuildPhi(ctx->llvm_builder, i1, "land");
    LLVMValueRef false_v = LLVMConstInt(i1, 0, 0);
    LLVMAddIncoming(phi, &false_v, &lhs_exit, 1);
    LLVMAddIncoming(phi, &r_b,    &rhs_exit, 1);
    return phi;
}

// Short-circuit || — evaluates rhs only when lhs is falsy.
inline LLVMValueRef visit_log_or(expr_node* e, ir_context* ctx) {
    LLVMTypeRef  i1   = LLVMInt1TypeInContext(ctx->llvm_ctx);
    LLVMValueRef fn   = ctx->current_func;

    LLVMBasicBlockRef rhs_bb   = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "lor_rhs");
    LLVMBasicBlockRef merge_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "lor_merge");

    LLVMValueRef lv  = visit_expr(e->lhs, ctx);
    LLVMValueRef l_b = LLVMBuildICmp(ctx->llvm_builder, LLVMIntNE, lv, LLVMConstNull(LLVMTypeOf(lv)), "lor_lhs_bool");
    LLVMBasicBlockRef lhs_exit = LLVMGetInsertBlock(ctx->llvm_builder);
    LLVMBuildCondBr(ctx->llvm_builder, l_b, merge_bb, rhs_bb);

    LLVMPositionBuilderAtEnd(ctx->llvm_builder, rhs_bb);
    LLVMValueRef rv  = visit_expr(e->rhs, ctx);
    LLVMValueRef r_b = LLVMBuildICmp(ctx->llvm_builder, LLVMIntNE, rv, LLVMConstNull(LLVMTypeOf(rv)), "lor_rhs_bool");
    LLVMBasicBlockRef rhs_exit = LLVMGetInsertBlock(ctx->llvm_builder);
    LLVMBuildBr(ctx->llvm_builder, merge_bb);

    LLVMPositionBuilderAtEnd(ctx->llvm_builder, merge_bb);
    LLVMValueRef phi = LLVMBuildPhi(ctx->llvm_builder, i1, "lor");
    LLVMValueRef true_v = LLVMConstInt(i1, 1, 0);
    LLVMAddIncoming(phi, &true_v, &lhs_exit, 1);
    LLVMAddIncoming(phi, &r_b,   &rhs_exit, 1);
    return phi;
}

inline LLVMValueRef visit_binary_expr(expr_node* e, ir_context* ctx) {
    // Short-circuit operators are handled before evaluating both operands.
    if (e->bop == binary_op::log_and) return visit_log_and(e, ctx);
    if (e->bop == binary_op::log_or)  return visit_log_or(e, ctx);

    // Evaluate both sides (left-to-right) for all other operators.
    LLVMValueRef lv = visit_expr(e->lhs, ctx);
    LLVMValueRef rv = visit_expr(e->rhs, ctx);
    bool is_fp = llvm_is_float(LLVMTypeOf(lv));

    switch (e->bop) {
        // ---- arithmetic ----
        case binary_op::add:
            return is_fp ? LLVMBuildFAdd(ctx->llvm_builder, lv, rv, "fadd")
                         : LLVMBuildAdd(ctx->llvm_builder,  lv, rv, "add");
        case binary_op::sub:
            return is_fp ? LLVMBuildFSub(ctx->llvm_builder, lv, rv, "fsub")
                         : LLVMBuildSub(ctx->llvm_builder,  lv, rv, "sub");
        case binary_op::mul:
            return is_fp ? LLVMBuildFMul(ctx->llvm_builder, lv, rv, "fmul")
                         : LLVMBuildMul(ctx->llvm_builder,  lv, rv, "mul");
        case binary_op::div:
            return is_fp ? LLVMBuildFDiv(ctx->llvm_builder, lv, rv, "fdiv")
                         : LLVMBuildSDiv(ctx->llvm_builder, lv, rv, "sdiv");
        case binary_op::mod:
            return is_fp ? LLVMBuildFRem(ctx->llvm_builder, lv, rv, "frem")
                         : LLVMBuildSRem(ctx->llvm_builder, lv, rv, "srem");

        // ---- comparison (yields i1) ----
        case binary_op::eq:
            return is_fp ? LLVMBuildFCmp(ctx->llvm_builder, LLVMRealOEQ, lv, rv, "fcmpeq")
                         : LLVMBuildICmp(ctx->llvm_builder, LLVMIntEQ,   lv, rv, "icmpeq");
        case binary_op::ne:
            return is_fp ? LLVMBuildFCmp(ctx->llvm_builder, LLVMRealONE, lv, rv, "fcmpne")
                         : LLVMBuildICmp(ctx->llvm_builder, LLVMIntNE,   lv, rv, "icmpne");
        case binary_op::lt:
            return is_fp ? LLVMBuildFCmp(ctx->llvm_builder, LLVMRealOLT, lv, rv, "fcmplt")
                         : LLVMBuildICmp(ctx->llvm_builder, LLVMIntSLT,  lv, rv, "icmplt");
        case binary_op::gt:
            return is_fp ? LLVMBuildFCmp(ctx->llvm_builder, LLVMRealOGT, lv, rv, "fcmpgt")
                         : LLVMBuildICmp(ctx->llvm_builder, LLVMIntSGT,  lv, rv, "icmpgt");
        case binary_op::lte:
            return is_fp ? LLVMBuildFCmp(ctx->llvm_builder, LLVMRealOLE, lv, rv, "fcmple")
                         : LLVMBuildICmp(ctx->llvm_builder, LLVMIntSLE,  lv, rv, "icmple");
        case binary_op::gte:
            return is_fp ? LLVMBuildFCmp(ctx->llvm_builder, LLVMRealOGE, lv, rv, "fcmpge")
                         : LLVMBuildICmp(ctx->llvm_builder, LLVMIntSGE,  lv, rv, "icmpge");

        // ---- bitwise ----
        case binary_op::bit_and: return LLVMBuildAnd(ctx->llvm_builder,  lv, rv, "band");
        case binary_op::bit_or:  return LLVMBuildOr(ctx->llvm_builder,   lv, rv, "bor");
        case binary_op::bit_xor: return LLVMBuildXor(ctx->llvm_builder,  lv, rv, "bxor");
        case binary_op::shl:     return LLVMBuildShl(ctx->llvm_builder,  lv, rv, "shl");
        case binary_op::shr:     return LLVMBuildAShr(ctx->llvm_builder, lv, rv, "ashr");

        default:
            throw std::runtime_error("IR: Unknown binary op in visit_binary_expr");
    }
}

// ------------------------------------------------------------------ assignment

inline LLVMValueRef visit_assign_expr(expr_node* e, ir_context* ctx) {
    LLVMValueRef rhs = visit_expr(e->rhs, ctx);
    LLVMValueRef ptr = visit_lvalue(e->lhs, ctx);
    bool is_fp = llvm_is_float(LLVMTypeOf(rhs));

    if (e->bop == binary_op::assign) {
        LLVMBuildStore(ctx->llvm_builder, rhs, ptr);
        return rhs;
    }

    // Compound: load lhs, apply op, store back.
    LLVMTypeRef elem_t = ctx->lookup_local_type(
        e->lhs->kind == expr_kind::identifier ? e->lhs->str_val : "");
    if (!elem_t) elem_t = LLVMTypeOf(rhs);

    LLVMValueRef lhs = LLVMBuildLoad2(ctx->llvm_builder, elem_t, ptr, "cmp_lhs");
    LLVMValueRef result = nullptr;

    switch (e->bop) {
        case binary_op::add_assign:
            result = is_fp ? LLVMBuildFAdd(ctx->llvm_builder, lhs, rhs, "fadd")
                           : LLVMBuildAdd(ctx->llvm_builder,  lhs, rhs, "add");  break;
        case binary_op::sub_assign:
            result = is_fp ? LLVMBuildFSub(ctx->llvm_builder, lhs, rhs, "fsub")
                           : LLVMBuildSub(ctx->llvm_builder,  lhs, rhs, "sub");  break;
        case binary_op::mul_assign:
            result = is_fp ? LLVMBuildFMul(ctx->llvm_builder, lhs, rhs, "fmul")
                           : LLVMBuildMul(ctx->llvm_builder,  lhs, rhs, "mul");  break;
        case binary_op::div_assign:
            result = is_fp ? LLVMBuildFDiv(ctx->llvm_builder, lhs, rhs, "fdiv")
                           : LLVMBuildSDiv(ctx->llvm_builder, lhs, rhs, "sdiv"); break;
        case binary_op::mod_assign:
            result = is_fp ? LLVMBuildFRem(ctx->llvm_builder, lhs, rhs, "frem")
                           : LLVMBuildSRem(ctx->llvm_builder, lhs, rhs, "srem"); break;
        case binary_op::and_assign: result = LLVMBuildAnd(ctx->llvm_builder,  lhs, rhs, "and");  break;
        case binary_op::or_assign:  result = LLVMBuildOr(ctx->llvm_builder,   lhs, rhs, "or");   break;
        case binary_op::xor_assign: result = LLVMBuildXor(ctx->llvm_builder,  lhs, rhs, "xor");  break;
        case binary_op::shl_assign: result = LLVMBuildShl(ctx->llvm_builder,  lhs, rhs, "shl");  break;
        case binary_op::shr_assign: result = LLVMBuildAShr(ctx->llvm_builder, lhs, rhs, "ashr"); break;
        default:
            throw std::runtime_error("IR: Unknown compound assignment op");
    }
    LLVMBuildStore(ctx->llvm_builder, result, ptr);
    return result;
}

// ------------------------------------------------------------------ call

inline LLVMValueRef visit_call_expr(expr_node* e, ir_context* ctx) {
    // Build argument values.
    std::vector<LLVMValueRef> args;
    for (auto* arg : e->args)
        args.push_back(visit_expr(arg, ctx));

    // Callee must be a named function (function pointers are an extension).
    if (e->callee->kind != expr_kind::identifier)
        throw std::runtime_error("IR: Only named function calls are supported at this stage");

    const std::string& fname = e->callee->str_val;
    auto fit = ctx->global_funcs.find(fname);
    if (fit == ctx->global_funcs.end())
        throw std::runtime_error("IR: Call to undeclared function '" + fname + "'");

    LLVMValueRef fn    = fit->second;
    LLVMTypeRef  fn_t  = ctx->global_func_types[fname];
    bool is_void = LLVMGetTypeKind(LLVMGetReturnType(fn_t)) == LLVMVoidTypeKind;

    return LLVMBuildCall2(ctx->llvm_builder, fn_t, fn,
                          args.data(), static_cast<unsigned>(args.size()),
                          is_void ? "" : "calltmp");
}

// ------------------------------------------------------------------ subscript

inline LLVMValueRef visit_subscript_expr(expr_node* e, ir_context* ctx) {
    LLVMValueRef base_ptr = visit_lvalue(e->object, ctx);
    LLVMValueRef idx      = visit_expr(e->index, ctx);
    LLVMTypeRef  elem_t   = ctx->lookup_local_type(
        e->object->kind == expr_kind::identifier ? e->object->str_val : "");
    if (!elem_t) elem_t = LLVMInt8TypeInContext(ctx->llvm_ctx);

    LLVMValueRef gep = LLVMBuildGEP2(ctx->llvm_builder, elem_t, base_ptr, &idx, 1, "elemptr");
    return LLVMBuildLoad2(ctx->llvm_builder, elem_t, gep, "elem");
}

// ------------------------------------------------------------------ member

inline LLVMValueRef visit_member_expr(expr_node* e, ir_context* ctx) {
    // visit_lvalue handles the GEP; we load the correct field type via struct_field_types.
    LLVMValueRef field_ptr = visit_lvalue(e, ctx);

    std::string tname;
    if (e->object->kind == expr_kind::identifier) {
        LLVMTypeRef elem = ctx->lookup_local_type(e->object->str_val);
        if (elem) tname = LLVMGetStructName(elem) ? LLVMGetStructName(elem) : "";
    }

    LLVMTypeRef field_t = LLVMInt8TypeInContext(ctx->llvm_ctx); // fallback
    auto names_it = ctx->struct_field_names.find(tname);
    auto types_it = ctx->struct_field_types.find(tname);
    if (names_it != ctx->struct_field_names.end() && types_it != ctx->struct_field_types.end()) {
        const auto& names = names_it->second;
        const auto& types = types_it->second;
        for (unsigned i = 0; i < names.size(); i++) {
            if (names[i] == e->member_name) { field_t = types[i]; break; }
        }
    }

    return LLVMBuildLoad2(ctx->llvm_builder, field_t, field_ptr, e->member_name.c_str());
}

// ------------------------------------------------------------------ cast

inline LLVMValueRef visit_cast_expr(expr_node* e, ir_context* ctx) {
    LLVMValueRef val     = visit_expr(e->operand, ctx);
    LLVMTypeRef  src_t   = LLVMTypeOf(val);
    LLVMTypeRef  dst_t   = llvm_type_of(e->cast_type, ctx);
    LLVMTypeKind src_k   = LLVMGetTypeKind(src_t);
    LLVMTypeKind dst_k   = LLVMGetTypeKind(dst_t);
    bool src_fp = llvm_is_float(src_t), dst_fp = llvm_is_float(dst_t);
    bool src_ptr = src_k == LLVMPointerTypeKind, dst_ptr = dst_k == LLVMPointerTypeKind;

    if (src_fp && dst_fp)   return LLVMBuildFPCast(ctx->llvm_builder,   val, dst_t, "fpcast");
    if (!src_fp && !dst_fp && !src_ptr && !dst_ptr) {
        unsigned sw = LLVMGetIntTypeWidth(src_t), dw = LLVMGetIntTypeWidth(dst_t);
        if (dw < sw) return LLVMBuildTrunc(ctx->llvm_builder,    val, dst_t, "trunc");
        if (dw > sw) return LLVMBuildSExt(ctx->llvm_builder,     val, dst_t, "sext"); // ZExt for unsigned
        return val; // same width — no-op
    }
    if (!src_fp && dst_fp)  return LLVMBuildSIToFP(ctx->llvm_builder, val, dst_t, "sitofp");
    if (src_fp && !dst_fp)  return LLVMBuildFPToSI(ctx->llvm_builder, val, dst_t, "fptosi");
    if (!src_ptr && dst_ptr) return LLVMBuildIntToPtr(ctx->llvm_builder, val, dst_t, "inttoptr");
    if (src_ptr && !dst_ptr) return LLVMBuildPtrToInt(ctx->llvm_builder, val, dst_t, "ptrtoint");
    return LLVMBuildBitCast(ctx->llvm_builder, val, dst_t, "bitcast"); // ptr -> ptr
}

// ------------------------------------------------------------------ sizeof

inline LLVMValueRef visit_sizeof_expr(expr_node* e, ir_context* ctx) {
    LLVMTypeRef measured_t;
    if (e->cast_type)
        measured_t = llvm_type_of(e->cast_type, ctx);
    else
        measured_t = LLVMTypeOf(visit_expr(e->operand, ctx));

    // LLVMSizeOf returns an i64 constant for the target data layout size.
    return LLVMSizeOf(measured_t);
}

// ------------------------------------------------------------------ ternary

inline LLVMValueRef visit_ternary_expr(expr_node* e, ir_context* ctx) {
    LLVMValueRef cond_val = visit_expr(e->cond, ctx);

    // Normalise condition to i1.
    if (LLVMGetTypeKind(LLVMTypeOf(cond_val)) != LLVMIntegerTypeKind ||
        LLVMGetIntTypeWidth(LLVMTypeOf(cond_val)) != 1) {
        cond_val = LLVMBuildICmp(ctx->llvm_builder, LLVMIntNE,
                                  cond_val, LLVMConstNull(LLVMTypeOf(cond_val)), "ternary_cond");
    }

    LLVMValueRef fn       = ctx->current_func;
    LLVMBasicBlockRef then_bb  = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "ternary_then");
    LLVMBasicBlockRef else_bb  = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "ternary_else");
    LLVMBasicBlockRef merge_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "ternary_merge");

    LLVMBuildCondBr(ctx->llvm_builder, cond_val, then_bb, else_bb);

    LLVMPositionBuilderAtEnd(ctx->llvm_builder, then_bb);
    LLVMValueRef then_val = visit_expr(e->then_e, ctx);
    if (!ctx->is_terminated()) LLVMBuildBr(ctx->llvm_builder, merge_bb);
    LLVMBasicBlockRef then_exit = LLVMGetInsertBlock(ctx->llvm_builder);

    LLVMPositionBuilderAtEnd(ctx->llvm_builder, else_bb);
    LLVMValueRef else_val = visit_expr(e->else_e, ctx);
    if (!ctx->is_terminated()) LLVMBuildBr(ctx->llvm_builder, merge_bb);
    LLVMBasicBlockRef else_exit = LLVMGetInsertBlock(ctx->llvm_builder);

    LLVMPositionBuilderAtEnd(ctx->llvm_builder, merge_bb);
    LLVMValueRef phi = LLVMBuildPhi(ctx->llvm_builder, LLVMTypeOf(then_val), "ternary");
    LLVMAddIncoming(phi, &then_val, &then_exit, 1);
    LLVMAddIncoming(phi, &else_val, &else_exit, 1);
    return phi;
}

// ------------------------------------------------------------------ annotation

inline LLVMValueRef visit_annotation_expr(expr_node* e, ir_context* ctx) {
    // Annotations carry no runtime value; emit a void-returning no-op.
    (void)e; (void)ctx;
    return LLVMConstNull(LLVMInt32TypeInContext(ctx->llvm_ctx));
}

// ------------------------------------------------------------------ dispatcher

inline LLVMValueRef visit_expr(expr_node* e, ir_context* ctx) {
    switch (e->kind) {
        case expr_kind::int_lit:    return visit_int_lit(e, ctx);
        case expr_kind::float_lit:  return visit_float_lit(e, ctx);
        case expr_kind::string_lit: return visit_string_lit(e, ctx);
        case expr_kind::char_lit:   return visit_char_lit(e, ctx);
        case expr_kind::bool_lit:   return visit_bool_lit(e, ctx);
        case expr_kind::identifier: return visit_identifier_expr(e, ctx);
        case expr_kind::unary:      return visit_unary_expr(e, ctx);
        case expr_kind::binary:     return visit_binary_expr(e, ctx);
        case expr_kind::assign:     return visit_assign_expr(e, ctx);
        case expr_kind::call:       return visit_call_expr(e, ctx);
        case expr_kind::subscript:  return visit_subscript_expr(e, ctx);
        case expr_kind::member:     return visit_member_expr(e, ctx);
        case expr_kind::cast:       return visit_cast_expr(e, ctx);
        case expr_kind::sizeof_e:   return visit_sizeof_expr(e, ctx);
        case expr_kind::ternary:    return visit_ternary_expr(e, ctx);
        case expr_kind::annotation: return visit_annotation_expr(e, ctx);
        default:
            throw std::runtime_error("IR: Unknown expr_kind");
    }
}
