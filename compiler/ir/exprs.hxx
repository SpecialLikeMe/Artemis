#pragma once
#include "types.hxx"
#include "names.hxx"

// Forward declare the dispatcher so recursive expressions compile.
inline LLVMValueRef visit_expr(expr_node* e, ir_context* ctx);
// Forward declare lvalue helper used by assign/unary addr_of.
inline LLVMValueRef visit_lvalue(expr_node* e, ir_context* ctx);
// Forward declare block visitor (defined in stmts.hxx; needed by except_expr handler here).
inline void visit_block_stmt(block_stmt* blk, ir_context* ctx);
// Forward declare subscript address helper (handles array vs pointer bases).
inline LLVMValueRef subscript_elem_ptr(expr_node* e, ir_context* ctx, LLVMTypeRef& elem_t_out);
// Forward declare generic-function instantiation (defined in decls.hxx).
inline void emit_generic_func_instance(func_decl* fd, const std::vector<LLVMTypeRef>& targs,
                                       const std::string& mangled, ir_context* ctx);
// Forward declare runtime safety check emitter (defined later in this file).
inline void emit_rt_check(expr_node* src, LLVMValueRef cond_ok, ir_context* ctx);

// ------------------------------------------------------------------ integer coercion helpers

// Bit width of an LLVM floating-point type (for FPExt/FPTrunc decisions).
inline unsigned llvm_float_bits(LLVMTypeRef t) {
    switch (LLVMGetTypeKind(t)) {
        case LLVMHalfTypeKind:    return 16;
        case LLVMBFloatTypeKind:  return 16;
        case LLVMFloatTypeKind:   return 32;
        case LLVMDoubleTypeKind:  return 64;
        case LLVMX86_FP80TypeKind:return 80;
        case LLVMFP128TypeKind:   return 128;
        case LLVMPPC_FP128TypeKind:return 128;
        default:                  return 0;
    }
}

// Coerce a value to dst_t, handling int<->int (trunc/sext/zext), float<->float
// (fpext/fptrunc) and int<->float (sitofp/fptosi). No-op when already matching
// or when no sensible conversion applies (e.g. pointers).
inline LLVMValueRef coerce_int_val(LLVMValueRef val, LLVMTypeRef dst_t, LLVMBuilderRef b) {
    LLVMTypeRef src_t = LLVMTypeOf(val);
    if (src_t == dst_t) return val;
    bool si = LLVMGetTypeKind(src_t) == LLVMIntegerTypeKind;
    bool di = LLVMGetTypeKind(dst_t) == LLVMIntegerTypeKind;
    bool sf = llvm_is_float(src_t);
    bool df = llvm_is_float(dst_t);

    if (si && di) {
        unsigned sw = LLVMGetIntTypeWidth(src_t), dw = LLVMGetIntTypeWidth(dst_t);
        if (sw == dw) return val;
        if (dw < sw)  return LLVMBuildTrunc(b, val, dst_t, "itrunc");
        // i1 (boolean comparison result) must zero-extend so true = 1, not -1.
        if (sw == 1)  return LLVMBuildZExt(b, val, dst_t, "zext");
        return LLVMBuildSExt(b, val, dst_t, "isext");
    }
    if (sf && df) {
        unsigned sw = llvm_float_bits(src_t), dw = llvm_float_bits(dst_t);
        if (sw == dw) return val;
        return dw < sw ? LLVMBuildFPTrunc(b, val, dst_t, "fptrunc")
                       : LLVMBuildFPExt(b,   val, dst_t, "fpext");
    }
    if (si && df) return LLVMBuildSIToFP(b, val, dst_t, "sitofp");
    if (sf && di) return LLVMBuildFPToSI(b, val, dst_t, "fptosi");
    return val;
}

// Coerce call arguments to match function parameter types (handles int<->int widening/narrowing).
// Skips variadic args (beyond the fixed param count).
inline void coerce_args_to_fn(LLVMTypeRef fn_t, std::vector<LLVMValueRef>& args,
                               LLVMBuilderRef b) {
    if (!fn_t || LLVMGetTypeKind(fn_t) != LLVMFunctionTypeKind) return;
    unsigned np = LLVMCountParamTypes(fn_t);
    if (np == 0) return;
    std::vector<LLVMTypeRef> pt(np);
    LLVMGetParamTypes(fn_t, pt.data());
    for (size_t i = 0; i < args.size() && i < np; ++i)
        args[i] = coerce_int_val(args[i], pt[i], b);
}

// Returns true if the expression is known to produce an unsigned integer value.
inline bool is_unsigned_expr(expr_node* e, ir_context* ctx) {
    if (!e) return false;
    switch (e->kind) {
        case expr_kind::cast:
            return e->cast_type && is_unsigned_type_node(e->cast_type);

        case expr_kind::identifier: {
            const std::string& n = e->str_val;
            if (ctx->lookup_local_unsigned(n)) return true;
            return ctx->global_var_unsigned.count(n) > 0;
        }

        case expr_kind::call:
            // Prefer resolved overload (set by analyzer for typed calls)
            if (e->resolved_overload && e->resolved_overload->ret_type)
                return is_unsigned_type_node(e->resolved_overload->ret_type);
            // Fall back to function name map
            if (e->callee && e->callee->kind == expr_kind::identifier) {
                auto it = ctx->global_func_ret_unsigned.find(e->callee->str_val);
                if (it != ctx->global_func_ret_unsigned.end()) return it->second;
            }
            return false;

        case expr_kind::binary:
        case expr_kind::assign:
            // Arithmetic/bitwise result is unsigned if either operand is unsigned
            return is_unsigned_expr(e->lhs, ctx) || is_unsigned_expr(e->rhs, ctx);

        case expr_kind::unary:
            if (e->uop == unary_op::addr_of) return false; // pointer result, not unsigned int
            return e->operand && is_unsigned_expr(e->operand, ctx);

        case expr_kind::subscript:
            // Element type inherits signedness from the array/pointer base
            return e->object && is_unsigned_expr(e->object, ctx);

        case expr_kind::member: {
            // Look up the field's unsigned flag in struct_field_unsigned
            if (!e->object) return false;
            std::string sname;
            if (e->object->kind == expr_kind::identifier) {
                LLVMTypeRef elem = ctx->lookup_local_type(e->object->str_val);
                if (elem && LLVMGetTypeKind(elem) == LLVMStructTypeKind) {
                    const char* sn = LLVMGetStructName(elem); if (sn) sname = sn;
                }
                if (sname.empty()) {
                    LLVMTypeRef dt = ctx->lookup_deref_type(e->object->str_val);
                    if (dt && LLVMGetTypeKind(dt) == LLVMStructTypeKind) {
                        const char* sn = LLVMGetStructName(dt); if (sn) sname = sn;
                    }
                }
            } else if (e->object->kind == expr_kind::unary &&
                       e->object->uop == unary_op::deref &&
                       e->object->operand &&
                       e->object->operand->kind == expr_kind::identifier) {
                LLVMTypeRef dt = ctx->lookup_deref_type(e->object->operand->str_val);
                if (dt && LLVMGetTypeKind(dt) == LLVMStructTypeKind) {
                    const char* sn = LLVMGetStructName(dt); if (sn) sname = sn;
                }
            }
            return !sname.empty() && ctx->lookup_field_unsigned(sname, e->member_name);
        }

        case expr_kind::ternary:
            // Result is unsigned if either branch is unsigned
            return is_unsigned_expr(e->then_e, ctx) || is_unsigned_expr(e->else_e, ctx);

        case expr_kind::null_coal:
            return is_unsigned_expr(e->lhs, ctx);

        default:
            return false;
    }
}

// Bring two integer operands to a common width before a binary instruction.
// is_cmp=true: extend the narrower operand to match the wider.
//   is_unsigned=true  -> zero-extend  (u8 < u32 comparisons)
//   is_unsigned=false -> sign-extend  (i8 < i32 comparisons)
// is_cmp=false: zero-extend the narrower to the wider (for arithmetic — two's complement
//   add/sub/mul are identical for signed and unsigned).
inline void homogenize_int_widths(LLVMValueRef& a, LLVMValueRef& b, LLVMBuilderRef builder,
                                   bool is_cmp = false, bool is_unsigned = false) {
    LLVMTypeRef ta = LLVMTypeOf(a), tb = LLVMTypeOf(b);
    bool ai = LLVMGetTypeKind(ta) == LLVMIntegerTypeKind;
    bool bi = LLVMGetTypeKind(tb) == LLVMIntegerTypeKind;
    bool af = llvm_is_float(ta), bf = llvm_is_float(tb);

    if (ai && bi) {
        unsigned wa = LLVMGetIntTypeWidth(ta), wb = LLVMGetIntTypeWidth(tb);
        if (wa == wb) return;
        if (is_cmp) {
            // Extend narrower to wider for comparison so no information is lost.
            if (wa < wb)
                a = is_unsigned ? LLVMBuildZExt(builder, a, tb, "zext")
                                : LLVMBuildSExt(builder, a, tb, "sext");
            else
                b = is_unsigned ? LLVMBuildZExt(builder, b, ta, "zext")
                                : LLVMBuildSExt(builder, b, ta, "sext");
        } else {
            if (wa < wb) a = LLVMBuildZExt(builder, a, tb, "zext");
            else         b = LLVMBuildZExt(builder, b, ta, "zext");
        }
        return;
    }
    if (af && bf) {
        unsigned wa = llvm_float_bits(ta), wb = llvm_float_bits(tb);
        if (wa == wb) return;
        if (wa < wb) a = LLVMBuildFPExt(builder, a, tb, "fpext");
        else         b = LLVMBuildFPExt(builder, b, ta, "fpext");
        return;
    }
    if (af && bi) { b = LLVMBuildSIToFP(builder, b, ta, "sitofp"); return; }
    if (bf && ai) { a = LLVMBuildSIToFP(builder, a, tb, "sitofp"); return; }
}

// ------------------------------------------------------------------ literals

inline LLVMValueRef visit_int_lit(expr_node* e, ir_context* ctx) {
    int64_t v = e->int_val;
    if (v < -2147483648LL || v > 2147483647LL) {
        LLVMTypeRef i64 = LLVMInt64TypeInContext(ctx->llvm_ctx);
        return LLVMConstInt(i64, static_cast<unsigned long long>(v), /*sign-extend=*/1);
    }
    LLVMTypeRef i32 = LLVMInt32TypeInContext(ctx->llvm_ctx);
    return LLVMConstInt(i32, static_cast<unsigned long long>(v), /*sign-extend=*/1);
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
    if (ptr && type) {
        // Array-to-pointer decay: an array used as a value yields a pointer to its
        // first element (the alloca address), not a load of the aggregate.
        if (LLVMIsAAllocaInst(ptr) &&
            LLVMGetTypeKind(LLVMGetAllocatedType(ptr)) == LLVMArrayTypeKind)
            return ptr;
        return LLVMBuildLoad2(ctx->llvm_builder, type, ptr, e->str_val.c_str());
    }

    // Global variable: load from global.
    // Enum constants are declared as global constants — return the initializer directly
    // so they can be used as case labels in switch instructions.
    // Also try namespace-qualified lookup (intra-namespace unqualified references).
    auto resolve_global_var = [&](const std::string& name) -> LLVMValueRef {
        auto it = ctx->global_vars.find(name);
        if (it != ctx->global_vars.end()) return it->second;
        if (!ctx->current_namespace.empty()) {
            std::string ns_name = ctx->current_namespace + "__NS_" + name;
            auto ns_it = ctx->global_vars.find(ns_name);
            if (ns_it != ctx->global_vars.end()) { e->str_val = ns_name; return ns_it->second; }
        }
        return nullptr;
    };
    if (LLVMValueRef gv = resolve_global_var(e->str_val)) {
        if (LLVMIsGlobalConstant(gv)) {
            LLVMValueRef init = LLVMGetInitializer(gv);
            if (init) return init;
        }
        LLVMTypeRef gt = LLVMGlobalGetValueType(gv);
        return LLVMBuildLoad2(ctx->llvm_builder, gt, gv, e->str_val.c_str());
    }

    // Function reference (when used as a value, e.g. for function pointers).
    auto fit = ctx->global_funcs.find(e->str_val);
    if (fit != ctx->global_funcs.end())
        return fit->second;
    if (!ctx->current_namespace.empty()) {
        std::string ns_func = ctx->current_namespace + "__NS_" + e->str_val;
        auto ns_fit = ctx->global_funcs.find(ns_func);
        if (ns_fit != ctx->global_funcs.end()) return ns_fit->second;
    }

    throw std::runtime_error("IR: Unknown identifier '" + e->str_val + "'");
}

// ------------------------------------------------------------------ struct name inference

// Recursively infer the struct name for a member/subscript expression.
// Returns "" if not determinable.
inline std::string infer_struct_tname(expr_node* e, ir_context* ctx) {
    switch (e->kind) {
        case expr_kind::identifier: {
            LLVMTypeRef t = ctx->lookup_local_type(e->str_val);
            if (t && LLVMGetTypeKind(t) == LLVMStructTypeKind) {
                const char* n = LLVMGetStructName(t); return n ? n : "";
            }
            LLVMTypeRef dt = ctx->lookup_deref_type(e->str_val);
            if (dt && LLVMGetTypeKind(dt) == LLVMStructTypeKind) {
                const char* n = LLVMGetStructName(dt); return n ? n : "";
            }
            return "";
        }
        case expr_kind::member: {
            std::string pn = infer_struct_tname(e->object, ctx);
            if (pn.empty()) return "";
            auto ni = ctx->struct_field_names.find(pn);
            auto ti = ctx->struct_field_types.find(pn);
            if (ni == ctx->struct_field_names.end() || ti == ctx->struct_field_types.end()) return "";
            const auto& ns = ni->second; const auto& ts = ti->second;
            for (unsigned i = 0; i < ns.size(); i++) {
                if (ns[i] == e->member_name && i < ts.size()) {
                    LLVMTypeRef ft = ts[i];
                    if (ft && LLVMGetTypeKind(ft) == LLVMStructTypeKind) {
                        const char* n = LLVMGetStructName(ft); return n ? n : "";
                    }
                    // Follow pointer-to-struct fields (e.g. a.ptr_field.member)
                    if (ft && LLVMGetTypeKind(ft) == LLVMPointerTypeKind) {
                        auto pi = ctx->struct_field_pointee_types.find(pn);
                        if (pi != ctx->struct_field_pointee_types.end() && i < pi->second.size()) {
                            LLVMTypeRef pt = pi->second[i];
                            if (pt && LLVMGetTypeKind(pt) == LLVMStructTypeKind) {
                                const char* n = LLVMGetStructName(pt); return n ? n : "";
                            }
                        }
                    }
                    return "";
                }
            }
            return "";
        }
        case expr_kind::subscript: {
            if (e->object->kind == expr_kind::identifier) {
                LLVMTypeRef t = ctx->lookup_local_type(e->object->str_val);
                if (t) {
                    if (LLVMGetTypeKind(t) == LLVMArrayTypeKind) {
                        LLVMTypeRef el = LLVMGetElementType(t);
                        if (el && LLVMGetTypeKind(el) == LLVMStructTypeKind) {
                            const char* n = LLVMGetStructName(el); return n ? n : "";
                        }
                    } else if (LLVMGetTypeKind(t) == LLVMStructTypeKind) {
                        // Array locals store elem_t (the struct type) directly.
                        const char* n = LLVMGetStructName(t); return n ? n : "";
                    }
                }
                LLVMTypeRef dt = ctx->lookup_deref_type(e->object->str_val);
                if (dt && LLVMGetTypeKind(dt) == LLVMStructTypeKind) {
                    const char* n = LLVMGetStructName(dt); return n ? n : "";
                }
            }
            // Handle subscript of a member expression: e.g., ptr.array_field[i].
            // The member returns a pointer-to-struct; subscript dereferences it.
            if (e->object->kind == expr_kind::member) {
                expr_node* mem = e->object;
                std::string parent = infer_struct_tname(mem->object, ctx);
                if (!parent.empty()) {
                    auto ni = ctx->struct_field_names.find(parent);
                    auto ti = ctx->struct_field_types.find(parent);
                    auto pi = ctx->struct_field_pointee_types.find(parent);
                    if (ni != ctx->struct_field_names.end() && ti != ctx->struct_field_types.end()) {
                        const auto& ns = ni->second;
                        const auto& ts = ti->second;
                        for (unsigned fi = 0; fi < ns.size(); fi++) {
                            if (ns[fi] == mem->member_name && fi < ts.size()) {
                                // Use stored pointee type — avoids LLVMGetElementType, which
                                // returns another opaque pointer in LLVM opaque-pointer mode.
                                LLVMTypeRef pointee = nullptr;
                                if (pi != ctx->struct_field_pointee_types.end() && fi < pi->second.size())
                                    pointee = pi->second[fi];
                                if (!pointee) {
                                    // Fallback for typed-pointer builds.
                                    LLVMTypeRef ft = ts[fi];
                                    if (ft && LLVMGetTypeKind(ft) == LLVMPointerTypeKind)
                                        pointee = LLVMGetElementType(ft);
                                }
                                if (pointee && LLVMGetTypeKind(pointee) == LLVMStructTypeKind) {
                                    const char* n = LLVMGetStructName(pointee);
                                    return n ? n : "";
                                }
                                break;
                            }
                        }
                    }
                }
            }
            return "";
        }
        case expr_kind::unary:
            if (e->uop == unary_op::deref && e->operand && e->operand->kind == expr_kind::identifier) {
                LLVMTypeRef dt = ctx->lookup_deref_type(e->operand->str_val);
                if (dt && LLVMGetTypeKind(dt) == LLVMStructTypeKind) {
                    const char* n = LLVMGetStructName(dt); return n ? n : "";
                }
            }
            return "";
        default: return "";
    }
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
            // Functions are valid lvalues for addr-of: &funcname
            auto fit = ctx->global_funcs.find(e->str_val);
            if (fit != ctx->global_funcs.end()) return fit->second;
            throw std::runtime_error("IR: Unknown lvalue '" + e->str_val + "'");
        }
        case expr_kind::unary:
            // *ptr  -> the pointer value itself is the address
            return visit_expr(e->operand, ctx);

        case expr_kind::subscript: {
            LLVMTypeRef elem_t = nullptr;
            return subscript_elem_ptr(e, ctx, elem_t);
        }
        case expr_kind::member: {
            // GEP into a struct.
            LLVMValueRef struct_ptr = visit_lvalue(e->object, ctx);
            // Look up the struct type from object's identifier name (best-effort).
            std::string tname;
            bool ptr_needs_load = false; // true when struct_ptr is ptr-to-ptr (e.g. self: Point**)
            if (e->object->kind == expr_kind::identifier) {
                LLVMTypeRef elem = ctx->lookup_local_type(e->object->str_val);
                // Only call LLVMGetStructName on actual struct types — calling it on a pointer or
                // other type is undefined behavior (LLVM uses a static cast internally).
                if (elem && LLVMGetTypeKind(elem) == LLVMStructTypeKind)
                    tname = LLVMGetStructName(elem) ? LLVMGetStructName(elem) : "";
                // If direct type is a pointer (e.g. self: Point*), check deref type for struct name.
                // Also need to load the pointer before GEP-ing into it.
                if (tname.empty()) {
                    LLVMTypeRef deref_t = ctx->lookup_deref_type(e->object->str_val);
                    if (deref_t && LLVMGetTypeKind(deref_t) == LLVMStructTypeKind) {
                        tname = LLVMGetStructName(deref_t) ? LLVMGetStructName(deref_t) : "";
                        ptr_needs_load = !tname.empty();
                    }
                }
            } else if (e->object->kind == expr_kind::unary &&
                       e->object->uop == unary_op::deref &&
                       e->object->operand->kind == expr_kind::identifier) {
                const std::string& opname = e->object->operand->str_val;
                // (*ptr).field — look up through the pointer's deref type
                LLVMTypeRef deref_t = ctx->lookup_deref_type(opname);
                if (deref_t && LLVMGetTypeKind(deref_t) == LLVMStructTypeKind)
                    tname = LLVMGetStructName(deref_t) ? LLVMGetStructName(deref_t) : "";

                // ADT enum payload access: (*x).field where x is an ADT enum (not a pointer).
                // We handle this here: GEP to payload, bitcast, return typed pointer.
                if (tname.empty()) {
                    LLVMTypeRef local_t = ctx->lookup_local_type(opname);
                    if (local_t && LLVMGetTypeKind(local_t) == LLVMStructTypeKind) {
                        const char* sn = LLVMGetStructName(local_t);
                        if (sn && ctx->adt_enums.count(sn)) {
                            enum_decl* ed = ctx->adt_enums[sn];
                            LLVMTypeRef i8t  = LLVMInt8TypeInContext(ctx->llvm_ctx);
                            LLVMTypeRef i32t = LLVMInt32TypeInContext(ctx->llvm_ctx);
                            // Find the named-struct or istruc_body variant that has this field
                            for (auto* ev : ed->variants) {
                                if (ev->kind != enum_variant_kind::named_struct &&
                                    ev->kind != enum_variant_kind::istruc_body) continue;

                                // Helper lambda to emit GEP for a field at byte_off
                                auto try_field_gep = [&](const std::string& fname, type_node* ftype, unsigned byte_off) -> LLVMValueRef {
                                    if (fname != e->member_name) return nullptr;
                                    LLVMTypeRef field_t = llvm_type_of(ftype, ctx);
                                    LLVMValueRef alloca_ = ctx->lookup_local(opname);
                                    LLVMValueRef payload_ptr = LLVMBuildStructGEP2(
                                        ctx->llvm_builder, local_t, alloca_, 1, "pay");
                                    LLVMValueRef zero  = LLVMConstInt(i32t, 0, 0);
                                    LLVMValueRef off_v = LLVMConstInt(i32t, byte_off, 0);
                                    LLVMValueRef bidx[2] = {zero, off_v};
                                    LLVMValueRef bp = LLVMBuildGEP2(ctx->llvm_builder,
                                        LLVMArrayType(i8t, 1), payload_ptr, bidx, 2, "byteptr");
                                    return LLVMBuildBitCast(ctx->llvm_builder, bp,
                                        LLVMPointerType(field_t, 0), "fieldptr");
                                };

                                unsigned byte_off = 0;
                                // named_struct fields
                                for (auto* f : ev->struct_fields) {
                                    LLVMValueRef r = try_field_gep(f->name, f->type, byte_off);
                                    if (r) return r;
                                    byte_off += adt_type_byte_size(llvm_type_of(f->type, ctx), ctx);
                                }
                                // istruc_body fields
                                if (ev->istruc_body) {
                                    for (auto* cf : ev->istruc_body->fields) {
                                        LLVMValueRef r = try_field_gep(cf->name, cf->type, byte_off);
                                        if (r) return r;
                                        byte_off += adt_type_byte_size(llvm_type_of(cf->type, ctx), ctx);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // Fallback: recursively infer struct name for nested member/subscript expressions.
            if (tname.empty())
                tname = infer_struct_tname(e->object, ctx);
            // For self.x where self is Point*: struct_ptr is Point** (alloca of self).
            // Load once to get the actual Point* before GEP.
            if (ptr_needs_load) {
                LLVMTypeRef ptr_t = ctx->lookup_local_type(e->object->str_val);
                struct_ptr = LLVMBuildLoad2(ctx->llvm_builder, ptr_t, struct_ptr, "selfload");
            }
            // For a.ptr_field.sub_field: visit_lvalue(a.ptr_field) returns a pointer to the
            // ptr_field storage (i.e. T**).  We must load once to get the T* before GEP-ing
            // into the sub_field.
            if (e->object->kind == expr_kind::member) {
                std::string parent_tn = infer_struct_tname(e->object->object, ctx);
                if (!parent_tn.empty()) {
                    auto ni2 = ctx->struct_field_names.find(parent_tn);
                    auto ti2 = ctx->struct_field_types.find(parent_tn);
                    if (ni2 != ctx->struct_field_names.end() && ti2 != ctx->struct_field_types.end()) {
                        const auto& ns2 = ni2->second;
                        const auto& ts2 = ti2->second;
                        for (unsigned ii = 0; ii < ns2.size(); ii++) {
                            if (ns2[ii] == e->object->member_name && ii < ts2.size()) {
                                LLVMTypeRef ft2 = ts2[ii];
                                if (ft2 && LLVMGetTypeKind(ft2) == LLVMPointerTypeKind)
                                    struct_ptr = LLVMBuildLoad2(ctx->llvm_builder, ft2, struct_ptr, "fieldload");
                                break;
                            }
                        }
                    }
                }
            }
            // ADT istruc variant field access: self.field inside an istruc method body.
            // tname = enum name (e.g. "io_error"), field is in variant payload.
            if (!tname.empty() && ctx->adt_enums.count(tname)) {
                enum_decl* ed = ctx->adt_enums.at(tname);
                LLVMTypeRef adt_t = ctx->struct_types[tname];
                LLVMTypeRef i8t   = LLVMInt8TypeInContext(ctx->llvm_ctx);
                const std::string& vname = ctx->current_class_name;
                for (auto* ev : ed->variants) {
                    bool vname_match = (ev->name == vname);
                    if (ev->kind == enum_variant_kind::istruc_body && ev->istruc_body)
                        vname_match = (ev->istruc_body->name == vname);
                    if (!vname_match) continue;
                    unsigned byte_off = 0;
                    auto try_payload_gep = [&](const std::string& fname, type_node* ftype) -> LLVMValueRef {
                        if (fname != e->member_name) return nullptr;
                        LLVMTypeRef field_t = llvm_type_of(ftype, ctx);
                        LLVMValueRef pay = LLVMBuildStructGEP2(ctx->llvm_builder, adt_t, struct_ptr, 1, "spay");
                        LLVMValueRef off_v = LLVMConstInt(LLVMInt64TypeInContext(ctx->llvm_ctx), byte_off, 0);
                        LLVMValueRef bp = LLVMBuildGEP2(ctx->llvm_builder, i8t, pay, &off_v, 1, "sbp");
                        return LLVMBuildBitCast(ctx->llvm_builder, bp,
                            LLVMPointerType(field_t, 0), "sfp");
                    };
                    for (auto* sf : ev->struct_fields) {
                        LLVMValueRef r = try_payload_gep(sf->name, sf->type);
                        if (r) return r;
                        byte_off += adt_type_byte_size(llvm_type_of(sf->type, ctx), ctx);
                    }
                    if (ev->istruc_body) {
                        for (auto* cf : ev->istruc_body->fields) {
                            LLVMValueRef r = try_payload_gep(cf->name, cf->type);
                            if (r) return r;
                            byte_off += adt_type_byte_size(llvm_type_of(cf->type, ctx), ctx);
                        }
                    }
                }
            }
            auto fit = ctx->struct_field_names.find(tname);
            if (fit == ctx->struct_field_names.end())
                throw std::runtime_error("IR: Struct '" + tname + "' not registered (member='" + e->member_name + "', obj_kind=" + std::to_string((int)e->object->kind) + ")");
            const auto& fields = fit->second;
            // Unions: the LLVM struct has only 1 body element; always GEP with index 0.
            bool is_union = ctx->union_names.count(tname) > 0;
            for (unsigned i = 0; i < fields.size(); i++) {
                if (fields[i] == e->member_name) {
                    LLVMTypeRef struct_t = ctx->struct_types[tname];
                    unsigned gep_idx = is_union ? 0 : i;
                    LLVMValueRef indices[2] = {
                        LLVMConstInt(LLVMInt32TypeInContext(ctx->llvm_ctx), 0, 0),
                        LLVMConstInt(LLVMInt32TypeInContext(ctx->llvm_ctx), gep_idx, 0)
                    };
                    LLVMValueRef gep = LLVMBuildGEP2(ctx->llvm_builder, struct_t, struct_ptr, indices, 2, "fieldptr");
                    // For union non-first fields: bitcast the pointer to the field's actual type.
                    if (is_union && i > 0) {
                        auto ti = ctx->struct_field_types.find(tname);
                        if (ti != ctx->struct_field_types.end() && i < ti->second.size()) {
                            LLVMTypeRef field_t = ti->second[i];
                            if (field_t && LLVMGetTypeKind(field_t) != LLVMGetTypeKind(
                                    ctx->struct_field_types[tname][0])) {
                                gep = LLVMBuildBitCast(ctx->llvm_builder, gep,
                                    LLVMPointerType(field_t, 0), "unioncast");
                            }
                        }
                    }
                    return gep;
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
            // Runtime null check for UNKNOWN sites from SMT.
            if (ctx->unsafe_ops.count(e)) {
                LLVMValueRef cond = LLVMBuildIsNotNull(ctx->llvm_builder, ptr, "nn_chk");
                emit_rt_check(e, cond, ctx);
            }
            // Look up the pointed-to type tracked at declaration time; fall back to i8.
            LLVMTypeRef elem_t = LLVMInt8TypeInContext(ctx->llvm_ctx);
            if (e->operand->kind == expr_kind::identifier) {
                LLVMTypeRef dt = ctx->lookup_deref_type(e->operand->str_val);
                if (dt) elem_t = dt;
            } else if (e->operand->kind == expr_kind::cast && e->operand->cast_type
                       && e->operand->cast_type->pointer_depth > 0) {
                type_node tmp = *e->operand->cast_type;
                tmp.pointer_depth -= 1;
                tmp.array_size.reset();
                elem_t = llvm_type_of(&tmp, ctx);
            } else if (e->operand->kind == expr_kind::member) {
                // *f.ptr_field: look up the field's pointee type from struct metadata.
                std::string tname = infer_struct_tname(e->operand->object, ctx);
                if (!tname.empty()) {
                    auto ni = ctx->struct_field_names.find(tname);
                    auto ti = ctx->struct_field_types.find(tname);
                    auto pi = ctx->struct_field_pointee_types.find(tname);
                    if (ni != ctx->struct_field_names.end() && ti != ctx->struct_field_types.end()) {
                        const auto& ns = ni->second;
                        const auto& ts = ti->second;
                        for (unsigned fi = 0; fi < ns.size(); fi++) {
                            if (ns[fi] == e->operand->member_name && fi < ts.size()) {
                                LLVMTypeRef ft = ts[fi];
                                if (ft && LLVMGetTypeKind(ft) == LLVMPointerTypeKind) {
                                    LLVMTypeRef pointee = nullptr;
                                    if (pi != ctx->struct_field_pointee_types.end() && fi < pi->second.size())
                                        pointee = pi->second[fi];
                                    if (!pointee) pointee = LLVMGetElementType(ft);
                                    if (pointee) elem_t = pointee;
                                }
                                break;
                            }
                        }
                    }
                }
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

    // Check for class operator overloads: if lhs is a struct, look for ClassName__MT_operator<op>.
    auto bop_suffix = [](binary_op op) -> std::string {
        switch (op) {
            case binary_op::add: return "+";  case binary_op::sub: return "-";
            case binary_op::mul: return "*";  case binary_op::div: return "/";
            case binary_op::mod: return "%";  case binary_op::eq:  return "==";
            case binary_op::ne:  return "!="; case binary_op::lt:  return "<";
            case binary_op::lte: return "<="; case binary_op::gt:  return ">";
            case binary_op::gte: return ">=";
            default: return "";
        }
    };
    if (e->lhs->kind == expr_kind::identifier || e->lhs->kind == expr_kind::member ||
        e->lhs->kind == expr_kind::subscript) {
        // Try to get the lhs struct name.
        std::string lhs_class;
        if (e->lhs->kind == expr_kind::identifier) {
            LLVMTypeRef lt = ctx->lookup_local_type(e->lhs->str_val);
            if (lt && LLVMGetTypeKind(lt) == LLVMStructTypeKind)
                lhs_class = LLVMGetStructName(lt) ? LLVMGetStructName(lt) : "";
        }
        if (!lhs_class.empty()) {
            std::string op_str = bop_suffix(e->bop);
            if (!op_str.empty()) {
                std::string mt_name = lhs_class + "__MT_operator" + op_str;
                auto fit = ctx->global_funcs.find(mt_name);
                if (fit != ctx->global_funcs.end()) {
                    LLVMValueRef self_ptr = visit_lvalue(e->lhs, ctx);
                    LLVMValueRef rhs_val  = visit_expr(e->rhs, ctx);
                    LLVMValueRef mt_args[2] = { self_ptr, rhs_val };
                    LLVMTypeRef mt_fn_t = ctx->global_func_types[mt_name];
                    bool mt_void = LLVMGetTypeKind(LLVMGetReturnType(mt_fn_t)) == LLVMVoidTypeKind;
                    return LLVMBuildCall2(ctx->llvm_builder, mt_fn_t, fit->second,
                                         mt_args, 2, mt_void ? "" : "opcall");
                }
            }
        }
    }

    // Evaluate both sides (left-to-right) for all other operators.
    LLVMValueRef lv = visit_expr(e->lhs, ctx);
    LLVMValueRef rv = visit_expr(e->rhs, ctx);

    LLVMTypeKind lk = LLVMGetTypeKind(LLVMTypeOf(lv));
    LLVMTypeKind rk = LLVMGetTypeKind(LLVMTypeOf(rv));
    bool l_ptr = lk == LLVMPointerTypeKind;
    bool r_ptr = rk == LLVMPointerTypeKind;

    // ---- pointer arithmetic: ptr +/- int  -> GEP ----
    if ((e->bop == binary_op::add || e->bop == binary_op::sub) && (l_ptr ^ r_ptr)) {
        LLVMValueRef pv  = l_ptr ? lv : rv;
        LLVMValueRef iv  = l_ptr ? rv : lv;
        // Determine the pointed-to element type from the pointer operand's declaration.
        expr_node* pexpr = l_ptr ? e->lhs : e->rhs;
        LLVMTypeRef elem_t = nullptr;
        if (pexpr->kind == expr_kind::identifier)
            elem_t = ctx->lookup_deref_type(pexpr->str_val);
        if (!elem_t) elem_t = LLVMInt8TypeInContext(ctx->llvm_ctx);
        if (e->bop == binary_op::sub)
            iv = LLVMBuildNeg(ctx->llvm_builder, iv, "negidx");
        return LLVMBuildGEP2(ctx->llvm_builder, elem_t, pv, &iv, 1, "ptradd");
    }

    // ---- pointer vs integer comparison (e.g. p == 0): make both pointers ----
    if (l_ptr && rk == LLVMIntegerTypeKind)
        rv = LLVMBuildIntToPtr(ctx->llvm_builder, rv, LLVMTypeOf(lv), "inttoptr");
    else if (r_ptr && lk == LLVMIntegerTypeKind)
        lv = LLVMBuildIntToPtr(ctx->llvm_builder, lv, LLVMTypeOf(rv), "inttoptr");

    // Determine if either operand is an unsigned type — affects comparison predicates,
    // division, remainder, and right-shift semantics.
    bool is_unsigned = is_unsigned_expr(e->lhs, ctx) || is_unsigned_expr(e->rhs, ctx);

    bool is_cmp_op = (e->bop == binary_op::eq || e->bop == binary_op::ne ||
                      e->bop == binary_op::lt || e->bop == binary_op::gt ||
                      e->bop == binary_op::lte || e->bop == binary_op::gte);
    homogenize_int_widths(lv, rv, ctx->llvm_builder, is_cmp_op, is_unsigned);
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
        case binary_op::div: {
            // Runtime div-by-zero check for UNKNOWN sites from SMT.
            if (!is_fp && ctx->unsafe_ops.count(e)) {
                LLVMValueRef zero = LLVMConstInt(LLVMTypeOf(rv), 0, 0);
                LLVMValueRef cond = LLVMBuildICmp(ctx->llvm_builder, LLVMIntNE, rv, zero, "dz_chk");
                emit_rt_check(e, cond, ctx);
            }
            return is_fp  ? LLVMBuildFDiv(ctx->llvm_builder,  lv, rv, "fdiv")
                 : is_unsigned ? LLVMBuildUDiv(ctx->llvm_builder, lv, rv, "udiv")
                               : LLVMBuildSDiv(ctx->llvm_builder, lv, rv, "sdiv");
        }
        case binary_op::mod: {
            if (!is_fp && ctx->unsafe_ops.count(e)) {
                LLVMValueRef zero = LLVMConstInt(LLVMTypeOf(rv), 0, 0);
                LLVMValueRef cond = LLVMBuildICmp(ctx->llvm_builder, LLVMIntNE, rv, zero, "dz_chk");
                emit_rt_check(e, cond, ctx);
            }
            return is_fp  ? LLVMBuildFRem(ctx->llvm_builder,  lv, rv, "frem")
                 : is_unsigned ? LLVMBuildURem(ctx->llvm_builder, lv, rv, "urem")
                               : LLVMBuildSRem(ctx->llvm_builder, lv, rv, "srem");
        }

        // ---- comparison (yields i1) ----
        case binary_op::eq:
            return is_fp ? LLVMBuildFCmp(ctx->llvm_builder, LLVMRealOEQ, lv, rv, "fcmpeq")
                         : LLVMBuildICmp(ctx->llvm_builder, LLVMIntEQ,   lv, rv, "icmpeq");
        case binary_op::ne:
            return is_fp ? LLVMBuildFCmp(ctx->llvm_builder, LLVMRealONE, lv, rv, "fcmpne")
                         : LLVMBuildICmp(ctx->llvm_builder, LLVMIntNE,   lv, rv, "icmpne");
        case binary_op::lt:
            return is_fp      ? LLVMBuildFCmp(ctx->llvm_builder, LLVMRealOLT, lv, rv, "fcmplt")
                 : is_unsigned ? LLVMBuildICmp(ctx->llvm_builder, LLVMIntULT,  lv, rv, "icmpult")
                               : LLVMBuildICmp(ctx->llvm_builder, LLVMIntSLT,  lv, rv, "icmpslt");
        case binary_op::gt:
            return is_fp      ? LLVMBuildFCmp(ctx->llvm_builder, LLVMRealOGT, lv, rv, "fcmpgt")
                 : is_unsigned ? LLVMBuildICmp(ctx->llvm_builder, LLVMIntUGT,  lv, rv, "icmpugt")
                               : LLVMBuildICmp(ctx->llvm_builder, LLVMIntSGT,  lv, rv, "icmpsgt");
        case binary_op::lte:
            return is_fp      ? LLVMBuildFCmp(ctx->llvm_builder, LLVMRealOLE, lv, rv, "fcmple")
                 : is_unsigned ? LLVMBuildICmp(ctx->llvm_builder, LLVMIntULE,  lv, rv, "icmpule")
                               : LLVMBuildICmp(ctx->llvm_builder, LLVMIntSLE,  lv, rv, "icmpsle");
        case binary_op::gte:
            return is_fp      ? LLVMBuildFCmp(ctx->llvm_builder, LLVMRealOGE, lv, rv, "fcmpge")
                 : is_unsigned ? LLVMBuildICmp(ctx->llvm_builder, LLVMIntUGE,  lv, rv, "icmpuge")
                               : LLVMBuildICmp(ctx->llvm_builder, LLVMIntSGE,  lv, rv, "icmpsge");

        // ---- bitwise ----
        case binary_op::bit_and: return LLVMBuildAnd(ctx->llvm_builder,  lv, rv, "band");
        case binary_op::bit_or:  return LLVMBuildOr(ctx->llvm_builder,   lv, rv, "bor");
        case binary_op::bit_xor: return LLVMBuildXor(ctx->llvm_builder,  lv, rv, "bxor");
        case binary_op::shl:     return LLVMBuildShl(ctx->llvm_builder,  lv, rv, "shl");
        case binary_op::shr:
            return is_unsigned ? LLVMBuildLShr(ctx->llvm_builder, lv, rv, "lshr")
                               : LLVMBuildAShr(ctx->llvm_builder, lv, rv, "ashr");

        default:
            throw std::runtime_error("IR: Unknown binary op in visit_binary_expr");
    }
}

// ------------------------------------------------------------------ assignment

// Best-effort LLVM element type of an assignable location, so RHS values can be
// coerced to the storage type (e.g. a double literal stored into a float field).
inline LLVMTypeRef lvalue_elem_type(expr_node* e, ir_context* ctx) {
    if (!e) return nullptr;
    switch (e->kind) {
        case expr_kind::identifier:
            return ctx->lookup_local_type(e->str_val);
        case expr_kind::unary:
            if (e->uop == unary_op::deref && e->operand &&
                e->operand->kind == expr_kind::identifier)
                return ctx->lookup_deref_type(e->operand->str_val);
            return nullptr;
        case expr_kind::subscript:
            if (e->object && e->object->kind == expr_kind::identifier) {
                LLVMTypeRef dt = ctx->lookup_deref_type(e->object->str_val);
                if (dt) return dt;                                   // pointer subscript
                return ctx->lookup_local_type(e->object->str_val);  // array element
            }
            return nullptr;
        case expr_kind::member: {
            std::string tname;
            expr_node* obj = e->object;
            if (obj && obj->kind == expr_kind::identifier) {
                LLVMTypeRef elem = ctx->lookup_local_type(obj->str_val);
                if (elem && LLVMGetTypeKind(elem) == LLVMStructTypeKind)
                    tname = LLVMGetStructName(elem) ? LLVMGetStructName(elem) : "";
                if (tname.empty()) {
                    LLVMTypeRef dt = ctx->lookup_deref_type(obj->str_val);
                    if (dt && LLVMGetTypeKind(dt) == LLVMStructTypeKind)
                        tname = LLVMGetStructName(dt) ? LLVMGetStructName(dt) : "";
                }
            } else if (obj && obj->kind == expr_kind::unary &&
                       obj->uop == unary_op::deref && obj->operand &&
                       obj->operand->kind == expr_kind::identifier) {
                LLVMTypeRef dt = ctx->lookup_deref_type(obj->operand->str_val);
                if (dt && LLVMGetTypeKind(dt) == LLVMStructTypeKind)
                    tname = LLVMGetStructName(dt) ? LLVMGetStructName(dt) : "";
            }
            auto fit = ctx->struct_field_names.find(tname);
            auto tyit = ctx->struct_field_types.find(tname);
            if (fit != ctx->struct_field_names.end() && tyit != ctx->struct_field_types.end()) {
                const auto& names = fit->second;
                for (unsigned i = 0; i < names.size(); ++i)
                    if (names[i] == e->member_name && i < tyit->second.size())
                        return tyit->second[i];
            }
            return nullptr;
        }
        default: return nullptr;
    }
}

inline LLVMValueRef visit_assign_expr(expr_node* e, ir_context* ctx) {
    LLVMValueRef rhs = visit_expr(e->rhs, ctx);
    LLVMValueRef ptr = visit_lvalue(e->lhs, ctx);
    bool is_fp = llvm_is_float(LLVMTypeOf(rhs));

    if (e->bop == binary_op::assign) {
        LLVMTypeRef elem_t = lvalue_elem_type(e->lhs, ctx);
        if (elem_t) rhs = coerce_int_val(rhs, elem_t, ctx->llvm_builder);
        // For class (istruc) types: route through operator= if defined.
        if (elem_t && LLVMGetTypeKind(elem_t) == LLVMStructTypeKind) {
            const char* sn = LLVMGetStructName(elem_t);
            if (sn) {
                std::string op_name = std::string(sn) + "__MT_operator=";
                auto fit = ctx->global_funcs.find(op_name);
                if (fit != ctx->global_funcs.end()) {
                    LLVMTypeRef op_ft = ctx->global_func_types[op_name];
                    LLVMValueRef mt_args[2] = { ptr, rhs };
                    bool mv = LLVMGetTypeKind(LLVMGetReturnType(op_ft)) == LLVMVoidTypeKind;
                    return LLVMBuildCall2(ctx->llvm_builder, op_ft, fit->second,
                                         mt_args, 2, mv ? "" : "opassign");
                }
            }
        }
        LLVMBuildStore(ctx->llvm_builder, rhs, ptr);
        return rhs;
    }

    // Compound: load lhs, apply op, store back.
    LLVMTypeRef elem_t = lvalue_elem_type(e->lhs, ctx);
    if (!elem_t) elem_t = LLVMTypeOf(rhs);

    bool is_unsigned_lhs = is_unsigned_expr(e->lhs, ctx);
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
            result = is_fp           ? LLVMBuildFDiv(ctx->llvm_builder,  lhs, rhs, "fdiv")
                   : is_unsigned_lhs ? LLVMBuildUDiv(ctx->llvm_builder,  lhs, rhs, "udiv")
                                     : LLVMBuildSDiv(ctx->llvm_builder,  lhs, rhs, "sdiv"); break;
        case binary_op::mod_assign:
            result = is_fp           ? LLVMBuildFRem(ctx->llvm_builder,  lhs, rhs, "frem")
                   : is_unsigned_lhs ? LLVMBuildURem(ctx->llvm_builder,  lhs, rhs, "urem")
                                     : LLVMBuildSRem(ctx->llvm_builder,  lhs, rhs, "srem"); break;
        case binary_op::and_assign: result = LLVMBuildAnd(ctx->llvm_builder,  lhs, rhs, "and");  break;
        case binary_op::or_assign:  result = LLVMBuildOr(ctx->llvm_builder,   lhs, rhs, "or");   break;
        case binary_op::xor_assign: result = LLVMBuildXor(ctx->llvm_builder,  lhs, rhs, "xor");  break;
        case binary_op::shl_assign: result = LLVMBuildShl(ctx->llvm_builder,  lhs, rhs, "shl");  break;
        case binary_op::shr_assign:
            result = is_unsigned_lhs ? LLVMBuildLShr(ctx->llvm_builder, lhs, rhs, "lshr")
                                     : LLVMBuildAShr(ctx->llvm_builder, lhs, rhs, "ashr"); break;
        default:
            throw std::runtime_error("IR: Unknown compound assignment op");
    }
    LLVMBuildStore(ctx->llvm_builder, result, ptr);
    return result;
}

// ------------------------------------------------------------------ call

inline LLVMValueRef visit_call_expr(expr_node* e, ir_context* ctx) {
    // Pre-pass: for context-inferred class_init args (.{...}), infer the struct type
    // from the callee's declared parameter types so visit_class_init can resolve them.
    std::vector<std::string> inferred_param_types(e->args.size(), "");
    if (e->callee->kind == expr_kind::identifier) {
        auto ft_it = ctx->global_func_types.find(e->callee->str_val);
        if (ft_it != ctx->global_func_types.end()) {
            LLVMTypeRef fn_t_pre = ft_it->second;
            unsigned np = LLVMCountParamTypes(fn_t_pre);
            std::vector<LLVMTypeRef> pt(np);
            if (np > 0) LLVMGetParamTypes(fn_t_pre, pt.data());
            for (size_t i = 0; i < e->args.size() && i < np; ++i) {
                if (pt[i] && LLVMGetTypeKind(pt[i]) == LLVMStructTypeKind) {
                    const char* sn = LLVMGetStructName(pt[i]);
                    if (sn && *sn) inferred_param_types[i] = sn;
                }
            }
        }
    }

    // Build argument values.
    std::vector<LLVMValueRef> args;
    for (size_t ai = 0; ai < e->args.size(); ++ai) {
        expr_node* arg = e->args[ai];
        if (arg->kind == expr_kind::class_init && !arg->init_type && !arg->object
            && !inferred_param_types[ai].empty()) {
            type_node tmp_tn;
            tmp_tn.name = inferred_param_types[ai];
            arg->init_type = &tmp_tn;
            args.push_back(visit_expr(arg, ctx));
            arg->init_type = nullptr;
        } else {
            args.push_back(visit_expr(arg, ctx));
        }
    }

    LLVMValueRef fn   = nullptr;
    LLVMTypeRef  fn_t = nullptr;

    // Case 1a: method call via member expression — obj.method(args) or obj->method(args)
    if (e->callee->kind == expr_kind::member) {
        expr_node* obj_expr    = e->callee->object;
        const std::string& mname = e->callee->member_name;

        // Resolve the class name from the object expression.
        std::string class_name;
        if (obj_expr->kind == expr_kind::identifier) {
            LLVMTypeRef elem = ctx->lookup_local_type(obj_expr->str_val);
            if (elem && LLVMGetTypeKind(elem) == LLVMStructTypeKind)
                class_name = LLVMGetStructName(elem) ? LLVMGetStructName(elem) : "";
            if (class_name.empty()) {
                LLVMTypeRef dt = ctx->lookup_deref_type(obj_expr->str_val);
                if (dt && LLVMGetTypeKind(dt) == LLVMStructTypeKind)
                    class_name = LLVMGetStructName(dt) ? LLVMGetStructName(dt) : "";
            }
            // ClassName.staticMethod(args): identifier not a local variable but IS a known class
            // (static call via dot syntax). Dispatch directly to ClassName__MT_method.
            if (class_name.empty() && ctx->class_infos.count(obj_expr->str_val)) {
                std::string mt_name = obj_expr->str_val + "__MT_" + mname;
                auto mfit = ctx->global_funcs.find(mt_name);
                if (mfit != ctx->global_funcs.end()) {
                    LLVMTypeRef mt_fn_t = ctx->global_func_types[mt_name];
                    bool mt_void = LLVMGetTypeKind(LLVMGetReturnType(mt_fn_t)) == LLVMVoidTypeKind;
                    return LLVMBuildCall2(ctx->llvm_builder, mt_fn_t, mfit->second,
                                         args.data(), static_cast<unsigned>(args.size()),
                                         mt_void ? "" : "stcall");
                }
            }
        } else if (obj_expr->kind == expr_kind::unary &&
                   obj_expr->uop == unary_op::deref &&
                   obj_expr->operand->kind == expr_kind::identifier) {
            // (*ptr).method(args) — deref of a pointer-to-struct identifier
            LLVMTypeRef dt = ctx->lookup_deref_type(obj_expr->operand->str_val);
            if (dt && LLVMGetTypeKind(dt) == LLVMStructTypeKind)
                class_name = LLVMGetStructName(dt) ? LLVMGetStructName(dt) : "";
        } else if (obj_expr->kind == expr_kind::member) {
            // Chained member: self.field.method(args) — infer class from field's type
            class_name = infer_struct_tname(obj_expr, ctx);
        }

        if (!class_name.empty()) {
            // &memstr fat-pointer vtable dispatch: a.mmap(n), a.rmap(p,n), a.deinit()
            if (class_name == "__memstr_fat__" && ctx->memstr_fat_type && ctx->memstr_vtable_type) {
                LLVMValueRef fat_alloca = ctx->lookup_local(obj_expr->str_val);
                LLVMValueRef fat_val    = LLVMBuildLoad2(ctx->llvm_builder, ctx->memstr_fat_type, fat_alloca, "fat");
                LLVMValueRef data_ptr   = LLVMBuildExtractValue(ctx->llvm_builder, fat_val, 0, "ms_data");
                LLVMValueRef vtable_ptr = LLVMBuildExtractValue(ctx->llvm_builder, fat_val, 1, "ms_vtbl");
                int slot = -1;
                if (mname == "mmap")   slot = 0;
                else if (mname == "rmap")   slot = 1;
                else if (mname == "deinit") slot = 2;
                if (slot >= 0) {
                    LLVMTypeRef ptr_t = LLVMPointerTypeInContext(ctx->llvm_ctx, 0);
                    LLVMTypeRef i64t  = LLVMInt64TypeInContext(ctx->llvm_ctx);
                    LLVMValueRef slot_indices[2] = {
                        LLVMConstInt(LLVMInt32TypeInContext(ctx->llvm_ctx), 0, 0),
                        LLVMConstInt(LLVMInt32TypeInContext(ctx->llvm_ctx), (unsigned)slot, 0)
                    };
                    LLVMValueRef fn_slot = LLVMBuildGEP2(ctx->llvm_builder, ctx->memstr_vtable_type,
                                                         vtable_ptr, slot_indices, 2, "vtslot");
                    LLVMValueRef fn_ptr  = LLVMBuildLoad2(ctx->llvm_builder, ptr_t, fn_slot, "fnptr");
                    // Build canonical call type and args
                    LLVMTypeRef call_fn_t;
                    std::vector<LLVMValueRef> call_args = {data_ptr};
                    if (slot == 0) { // mmap: ptr(ptr, i64)
                        LLVMTypeRef ps[2] = {ptr_t, i64t};
                        call_fn_t = LLVMFunctionType(ptr_t, ps, 2, 0);
                        if (!args.empty()) {
                            LLVMValueRef n = coerce_int_val(args[0], i64t, ctx->llvm_builder);
                            call_args.push_back(n);
                        }
                    } else if (slot == 1) { // rmap: void(ptr, ptr, i64)
                        LLVMTypeRef ps[3] = {ptr_t, ptr_t, i64t};
                        call_fn_t = LLVMFunctionType(LLVMVoidTypeInContext(ctx->llvm_ctx), ps, 3, 0);
                        for (auto& a : args) call_args.push_back(a);
                    } else { // deinit: void(ptr)
                        call_fn_t = LLVMFunctionType(LLVMVoidTypeInContext(ctx->llvm_ctx), &ptr_t, 1, 0);
                        // ignore extra args in call (vector.arc calls a.deinit(ptr) wrongly)
                    }
                    bool is_void = LLVMGetTypeKind(LLVMGetReturnType(call_fn_t)) == LLVMVoidTypeKind;
                    return LLVMBuildCall2(ctx->llvm_builder, call_fn_t, fn_ptr,
                                         call_args.data(), (unsigned)call_args.size(),
                                         is_void ? "" : "mscall");
                }
            }

            // Determine if obj_expr is a pointer-typed identifier (e.g. `self: &Foo`).
            // visit_lvalue returns the alloca, which for pointer params holds a ptr-to-struct —
            // one extra indirection. Load it so the callee receives the actual struct pointer.
            bool self_needs_load = false;
            if (obj_expr->kind == expr_kind::identifier) {
                LLVMTypeRef elem = ctx->lookup_local_type(obj_expr->str_val);
                if (!elem || LLVMGetTypeKind(elem) != LLVMStructTypeKind) {
                    LLVMTypeRef dt = ctx->lookup_deref_type(obj_expr->str_val);
                    if (dt && LLVMGetTypeKind(dt) == LLVMStructTypeKind)
                        self_needs_load = true;
                }
            }
            auto resolve_self_ptr = [&]() -> LLVMValueRef {
                LLVMValueRef p = visit_lvalue(obj_expr, ctx);
                if (self_needs_load) {
                    LLVMTypeRef ptr_t = ctx->lookup_local_type(obj_expr->str_val);
                    p = LLVMBuildLoad2(ctx->llvm_builder, ptr_t, p, "selfload");
                }
                return p;
            };

            // Walk inheritance chain: look for ClassName__MT_method, then BaseClass__MT_method, etc.
            std::string search = class_name;
            while (!search.empty()) {
                std::string mt_name = search + "__MT_" + mname;
                auto mfit = ctx->global_funcs.find(mt_name);
                if (mfit != ctx->global_funcs.end()) {
                    // Prepend &obj as self. The self pointer is always cast to the declaring
                    // class pointer by the IR (both have compatible layout due to inheritance).
                    LLVMValueRef self_ptr = resolve_self_ptr();
                    std::vector<LLVMValueRef> mt_args = { self_ptr };
                    mt_args.insert(mt_args.end(), args.begin(), args.end());
                    LLVMTypeRef mt_fn_t = ctx->global_func_types[mt_name];
                    coerce_args_to_fn(mt_fn_t, mt_args, ctx->llvm_builder);
                    // Coerce concrete struct args to &memstr fat pointers
                    if (ctx->memstr_fat_type) {
                        unsigned np2 = LLVMCountParamTypes(mt_fn_t);
                        std::vector<LLVMTypeRef> pts2(np2);
                        if (np2) LLVMGetParamTypes(mt_fn_t, pts2.data());
                        for (size_t ai = 0; ai < e->args.size(); ++ai) {
                            size_t pi = ai + 1;
                            if (pi < np2 && pts2[pi] == ctx->memstr_fat_type) {
                                LLVMTypeRef arg_t = LLVMTypeOf(mt_args[pi]);
                                if (LLVMGetTypeKind(arg_t) == LLVMStructTypeKind) {
                                    const char* sn = LLVMGetStructName(arg_t);
                                    auto vit2 = ctx->memstr_vtables.find(sn ? sn : "");
                                    if (vit2 != ctx->memstr_vtables.end()) {
                                        LLVMValueRef addr = visit_lvalue(e->args[ai], ctx);
                                        LLVMValueRef fat  = LLVMGetUndef(ctx->memstr_fat_type);
                                        fat = LLVMBuildInsertValue(ctx->llvm_builder, fat, addr,           0, "fd");
                                        fat = LLVMBuildInsertValue(ctx->llvm_builder, fat, vit2->second,   1, "fv");
                                        mt_args[pi] = fat;
                                    }
                                }
                            }
                        }
                    }
                    bool mt_void = LLVMGetTypeKind(LLVMGetReturnType(mt_fn_t)) == LLVMVoidTypeKind;
                    return LLVMBuildCall2(ctx->llvm_builder, mt_fn_t, mfit->second,
                                         mt_args.data(), static_cast<unsigned>(mt_args.size()),
                                         mt_void ? "" : "mtcall");
                }
                // Try base class
                auto ci = ctx->class_infos.find(search);
                search = (ci != ctx->class_infos.end()) ? ci->second.base_name : "";
            }
            // ADT enum istruc variant method: e.method() where e is an ADT enum.
            // Search each istruc_body variant using the qualified name (EnumName__NS_VariantName).
            if (ctx->adt_enums.count(class_name)) {
                enum_decl* ed = ctx->adt_enums.at(class_name);
                for (auto* ev : ed->variants) {
                    if (ev->kind != enum_variant_kind::istruc_body || !ev->istruc_body) continue;
                    std::string mt_name = ev->istruc_body->name + "__MT_" + mname;
                    auto mfit = ctx->global_funcs.find(mt_name);
                    if (mfit != ctx->global_funcs.end()) {
                        LLVMValueRef self_ptr = resolve_self_ptr();
                        std::vector<LLVMValueRef> mt_args = { self_ptr };
                        mt_args.insert(mt_args.end(), args.begin(), args.end());
                        LLVMTypeRef mt_fn_t = ctx->global_func_types[mt_name];
                        bool mt_void = LLVMGetTypeKind(LLVMGetReturnType(mt_fn_t)) == LLVMVoidTypeKind;
                        return LLVMBuildCall2(ctx->llvm_builder, mt_fn_t, mfit->second,
                                             mt_args.data(), static_cast<unsigned>(mt_args.size()),
                                             mt_void ? "" : "admtcall");
                    }
                }
            }
        }
    }

    // Case 1b: ADT enum variant constructor call — EnumName::VariantName(args...)
    // Detected when callee is a member expr whose object is a known ADT enum type name
    // and the variant has a registered constructor function.
    if (e->callee->kind == expr_kind::member) {
        expr_node* obj_expr = e->callee->object;
        if (obj_expr->kind == expr_kind::identifier) {
            auto adt_it = ctx->adt_enums.find(obj_expr->str_val);
            if (adt_it != ctx->adt_enums.end() && !ctx->lookup_local(obj_expr->str_val)) {
                std::string ctor = obj_expr->str_val + "__" + e->callee->member_name + "__ctor";
                auto cit = ctx->global_funcs.find(ctor);
                if (cit != ctx->global_funcs.end()) {
                    LLVMTypeRef ctn_t = ctx->global_func_types[ctor];
                    bool cv = LLVMGetTypeKind(LLVMGetReturnType(ctn_t)) == LLVMVoidTypeKind;
                    return LLVMBuildCall2(ctx->llvm_builder, ctn_t, cit->second,
                        args.data(), (unsigned)args.size(), cv ? "" : "adtctor");
                }
            }
        }
    }

    // Case 1: function pointer call (callee is a non-identifier expression)
    if (e->callee->kind != expr_kind::identifier) {
        LLVMValueRef fp_val = visit_expr(e->callee, ctx);
        LLVMTypeRef fp_t = LLVMTypeOf(fp_val);
        if (LLVMGetTypeKind(fp_t) == LLVMPointerTypeKind) {
            // It's a pointer: load and call (function pointer stored in memory)
            LLVMTypeRef pointed_t = LLVMGetElementType(fp_t);
            if (LLVMGetTypeKind(pointed_t) == LLVMFunctionTypeKind) {
                // It's a direct function pointer
                fn   = fp_val;
                fn_t = pointed_t;
            } else {
                // Load through pointer
                LLVMValueRef loaded = LLVMBuildLoad2(ctx->llvm_builder, pointed_t, fp_val, "fpload");
                LLVMTypeRef loaded_t = LLVMTypeOf(loaded);
                if (LLVMGetTypeKind(loaded_t) == LLVMPointerTypeKind) {
                    fn   = loaded;
                    fn_t = LLVMGetElementType(loaded_t);
                } else {
                    fn = loaded; fn_t = loaded_t;
                }
            }
        } else {
            fn = fp_val; fn_t = fp_t;
        }
        if (!fn_t || LLVMGetTypeKind(fn_t) != LLVMFunctionTypeKind)
            throw std::runtime_error("IR: Callee expression is not callable");
        bool is_void = LLVMGetTypeKind(LLVMGetReturnType(fn_t)) == LLVMVoidTypeKind;
        return LLVMBuildCall2(ctx->llvm_builder, fn_t, fn,
                              args.data(), static_cast<unsigned>(args.size()),
                              is_void ? "" : "calltmp");
    }

    const std::string& fname = e->callee->str_val;

    // Case 1b: generic function call — monomorphize on demand.
    {
        auto git = ctx->generic_funcs.find(fname);
        if (git != ctx->generic_funcs.end()) {
            func_decl* tmpl = git->second;
            std::vector<LLVMTypeRef> targs;
            if (!e->type_args.empty()) {
                for (auto* ta : e->type_args) targs.push_back(llvm_type_of(ta, ctx));
            } else {
                // Infer each type parameter from argument types.
                targs.assign(tmpl->type_params.size(), nullptr);
                for (size_t pi = 0; pi < tmpl->params.size() && pi < args.size(); ++pi) {
                    auto* pt = tmpl->params[pi].type;
                    if (pt && !pt->is_primitive && pt->name && pt->pointer_depth == 0) {
                        for (size_t ti = 0; ti < tmpl->type_params.size(); ++ti) {
                            if (tmpl->type_params[ti] == *pt->name && !targs[ti])
                                targs[ti] = LLVMTypeOf(args[pi]);
                        }
                    }
                }
                for (auto& t : targs)
                    if (!t) t = LLVMInt32TypeInContext(ctx->llvm_ctx);
            }
            std::string mangled = generic_func_mangled(tmpl->name, targs);
            if (ctx->global_funcs.find(mangled) == ctx->global_funcs.end())
                emit_generic_func_instance(tmpl, targs, mangled, ctx);
            LLVMValueRef gfn  = ctx->global_funcs[mangled];
            LLVMTypeRef  gft  = ctx->global_func_types[mangled];
            // Coerce integer args to the concrete parameter widths.
            unsigned np = LLVMCountParamTypes(gft);
            std::vector<LLVMTypeRef> pts(np);
            LLVMGetParamTypes(gft, pts.data());
            for (unsigned i = 0; i < args.size() && i < np; ++i)
                args[i] = coerce_int_val(args[i], pts[i], ctx->llvm_builder);
            bool gv = LLVMGetTypeKind(LLVMGetReturnType(gft)) == LLVMVoidTypeKind;
            return LLVMBuildCall2(ctx->llvm_builder, gft, gfn,
                                  args.data(), static_cast<unsigned>(args.size()),
                                  gv ? "" : "gcall");
        }
    }

    // Case 2: resolved overload (set by analyzer)
    std::string ir_name = fname;
    if (e->resolved_overload) {
        ir_name = ir_func_name(e->resolved_overload);
    }

    // Look up in global_funcs; try several fallbacks in order
    auto resolve_fn = [&]() -> bool {
        if (ctx->global_funcs.count(ir_name)) return true;
        // Try original unmangled name
        if (ctx->global_funcs.count(fname)) { ir_name = fname; return true; }
        // Intra-namespace bare-name call: try ns__NS_fname
        if (!ctx->current_namespace.empty()) {
            std::string ns_qual = ctx->current_namespace + "__NS_" + fname;
            if (ctx->global_funcs.count(ns_qual)) { ir_name = ns_qual; return true; }
        }
        return false;
    };
    if (!resolve_fn()) {
        // Try as a local function pointer variable: fp(args)
        LLVMValueRef fp_alloca = ctx->lookup_local(fname);
        LLVMTypeRef  fp_ptr_t  = ctx->lookup_local_type(fname);
        if (fp_alloca && fp_ptr_t && LLVMGetTypeKind(fp_ptr_t) == LLVMPointerTypeKind) {
            LLVMTypeRef fn_elem_t = ctx->lookup_deref_type(fname);
            if (!fn_elem_t) fn_elem_t = LLVMGetElementType(fp_ptr_t);
            if (fn_elem_t && LLVMGetTypeKind(fn_elem_t) == LLVMFunctionTypeKind) {
                LLVMValueRef fp_val = LLVMBuildLoad2(ctx->llvm_builder, fp_ptr_t, fp_alloca, "fp");
                bool is_void_fp = LLVMGetTypeKind(LLVMGetReturnType(fn_elem_t)) == LLVMVoidTypeKind;
                return LLVMBuildCall2(ctx->llvm_builder, fn_elem_t, fp_val,
                                     args.data(), static_cast<unsigned>(args.size()),
                                     is_void_fp ? "" : "calltmp");
            }
        }
        throw std::runtime_error("IR: Call to undeclared function '" + fname + "'");
    }
    auto fit = ctx->global_funcs.find(ir_name);

    fn   = fit->second;
    fn_t = ctx->global_func_types[ir_name];
    coerce_args_to_fn(fn_t, args, ctx->llvm_builder);
    // Coerce concrete memstr struct args to &memstr fat pointers (same as in method call path)
    if (ctx->memstr_fat_type) {
        unsigned np = LLVMCountParamTypes(fn_t);
        std::vector<LLVMTypeRef> pts(np);
        if (np) LLVMGetParamTypes(fn_t, pts.data());
        for (size_t ai = 0; ai < e->args.size() && ai < np; ++ai) {
            if (pts[ai] == ctx->memstr_fat_type) {
                LLVMTypeRef arg_t = LLVMTypeOf(args[ai]);
                if (LLVMGetTypeKind(arg_t) == LLVMStructTypeKind) {
                    const char* sn = LLVMGetStructName(arg_t);
                    auto vit = ctx->memstr_vtables.find(sn ? sn : "");
                    if (vit != ctx->memstr_vtables.end()) {
                        LLVMValueRef addr = visit_lvalue(e->args[ai], ctx);
                        LLVMValueRef fat  = LLVMGetUndef(ctx->memstr_fat_type);
                        fat = LLVMBuildInsertValue(ctx->llvm_builder, fat, addr,        0, "fd");
                        fat = LLVMBuildInsertValue(ctx->llvm_builder, fat, vit->second, 1, "fv");
                        args[ai] = fat;
                    }
                }
            }
        }
    }
    bool is_void = LLVMGetTypeKind(LLVMGetReturnType(fn_t)) == LLVMVoidTypeKind;

    return LLVMBuildCall2(ctx->llvm_builder, fn_t, fn,
                          args.data(), static_cast<unsigned>(args.size()),
                          is_void ? "" : "calltmp");
}

// ------------------------------------------------------------------ runtime safety checks

static inline uint32_t fnv32_str(const char* s) {
    uint32_t h = 2166136261u;
    while (*s) { h ^= (uint8_t)*s++; h *= 16777619u; }
    return h;
}

// Emit a conditional runtime check. cond_ok is an i1 that is true when safe.
// Errors in !T functions return error.mm.X; non-error functions trap.
// No-op when src is not in ctx->unsafe_ops (i.e., SMT said GOOD).
inline void emit_rt_check(expr_node* src, LLVMValueRef cond_ok, ir_context* ctx) {
    if (!src || !ctx->unsafe_ops.count(src)) return;
    check_kind ck = ctx->unsafe_ops.at(src);

    // Hint to the branch predictor that the check almost always passes.
    LLVMTypeRef i1 = LLVMInt1TypeInContext(ctx->llvm_ctx);
    LLVMTypeRef i1p[2] = {i1, i1};
    LLVMTypeRef expect_fn_t = LLVMFunctionType(i1, i1p, 2, 0);
    LLVMValueRef expect_fn  = LLVMGetNamedFunction(ctx->llvm_mod, "llvm.expect.i1");
    if (!expect_fn) expect_fn = LLVMAddFunction(ctx->llvm_mod, "llvm.expect.i1", expect_fn_t);
    LLVMValueRef expect_args[2] = { cond_ok, LLVMConstInt(i1, 1, 0) };
    LLVMValueRef hinted = LLVMBuildCall2(ctx->llvm_builder, expect_fn_t, expect_fn,
                                          expect_args, 2, "rt_hint");

    LLVMValueRef fn       = ctx->current_func;
    LLVMBasicBlockRef ok_bb   = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "rt_ok");
    LLVMBasicBlockRef fail_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "rt_fail");
    LLVMBuildCondBr(ctx->llvm_builder, hinted, ok_bb, fail_bb);

    // Fail path
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, fail_bb);
    if (ctx->current_func_is_error_union && ctx->current_error_union_type) {
        const char* err_ns = nullptr;
        switch (ck) {
        case check_kind::bounds:     err_ns = "mm.out_of_bounds"; break;
        case check_kind::null_deref: err_ns = "mm.null_deref";    break;
        case check_kind::div_zero:   err_ns = "mm.div_zero";      break;
        }
        uint32_t err_code = err_ns ? fnv32_str(err_ns) : 0u;
        if (err_ns) ctx->error_registry.push_back({err_code, err_ns});
        LLVMTypeRef eu_t  = ctx->current_error_union_type;
        LLVMTypeRef i32t  = LLVMInt32TypeInContext(ctx->llvm_ctx);
        LLVMValueRef eu_v = LLVMGetUndef(eu_t);
        eu_v = LLVMBuildInsertValue(ctx->llvm_builder, eu_v,
                                    LLVMConstInt(i32t, err_code, 0), 0, "eu_err");
        LLVMBuildRet(ctx->llvm_builder, eu_v);
    } else {
        LLVMTypeRef void_t    = LLVMVoidTypeInContext(ctx->llvm_ctx);
        LLVMTypeRef trap_fn_t = LLVMFunctionType(void_t, nullptr, 0, 0);
        LLVMValueRef trap_fn  = LLVMGetNamedFunction(ctx->llvm_mod, "llvm.trap");
        if (!trap_fn) trap_fn = LLVMAddFunction(ctx->llvm_mod, "llvm.trap", trap_fn_t);
        LLVMBuildCall2(ctx->llvm_builder, trap_fn_t, trap_fn, nullptr, 0, "");
        LLVMBuildUnreachable(ctx->llvm_builder);
    }

    LLVMPositionBuilderAtEnd(ctx->llvm_builder, ok_bb);
}

// ------------------------------------------------------------------ subscript

// Compute the address of element e->object[e->index], handling both array bases
// (GEP from the array's address) and pointer bases (load the pointer, then GEP).
inline LLVMValueRef subscript_elem_ptr(expr_node* e, ir_context* ctx, LLVMTypeRef& elem_t_out) {
    LLVMValueRef idx = visit_expr(e->index, ctx);
    const std::string oname =
        e->object->kind == expr_kind::identifier ? e->object->str_val : "";

    // ADT enum payload access: (*x)[N] where x is an ADT enum local (not a pointer).
    // Resolves to: bitcast(&x.__payload[byte_offset]) → field_type*
    if (e->object->kind == expr_kind::unary && e->object->uop == unary_op::deref &&
        e->object->operand->kind == expr_kind::identifier) {
        const std::string& xname = e->object->operand->str_val;
        LLVMTypeRef local_t = ctx->lookup_local_type(xname);
        if (local_t && LLVMGetTypeKind(local_t) == LLVMStructTypeKind) {
            const char* sn = LLVMGetStructName(local_t);
            if (sn && ctx->adt_enums.count(sn)) {
                enum_decl* ed = ctx->adt_enums[sn];
                // Find the first tuple variant and use its field types for the index
                int field_idx = (int)LLVMConstIntGetSExtValue(idx);
                LLVMTypeRef field_type = LLVMInt8TypeInContext(ctx->llvm_ctx);
                unsigned byte_off = 0;
                for (auto* ev : ed->variants) {
                    if (ev->kind == enum_variant_kind::tuple && field_idx < (int)ev->tuple_types.size()) {
                        for (int fi = 0; fi < field_idx; fi++)
                            byte_off += adt_type_byte_size(llvm_type_of(ev->tuple_types[fi], ctx), ctx);
                        field_type = llvm_type_of(ev->tuple_types[field_idx], ctx);
                        break;
                    }
                }
                LLVMValueRef alloca = ctx->lookup_local(xname);
                LLVMTypeRef adt_t   = local_t;
                // GEP to payload field (index 1 of the outer struct)
                LLVMValueRef payload_ptr = LLVMBuildStructGEP2(ctx->llvm_builder, adt_t, alloca, 1, "pay");
                // GEP into the byte array
                LLVMTypeRef i8t = LLVMInt8TypeInContext(ctx->llvm_ctx);
                LLVMValueRef off_v = LLVMConstInt(LLVMInt32TypeInContext(ctx->llvm_ctx), byte_off, 0);
                LLVMValueRef zero  = LLVMConstInt(LLVMInt32TypeInContext(ctx->llvm_ctx), 0, 0);
                LLVMValueRef bidx[2] = {zero, off_v};
                LLVMValueRef byte_ptr = LLVMBuildGEP2(ctx->llvm_builder,
                    LLVMArrayType(i8t, 1), payload_ptr, bidx, 2, "byteptr");
                LLVMValueRef typed_ptr = LLVMBuildBitCast(ctx->llvm_builder, byte_ptr,
                    LLVMPointerType(field_type, 0), "fieldptr");
                elem_t_out = field_type;
                return typed_ptr;
            }
        }
    }

    // Pointer base: the variable holds a pointer (not an array); load it, then index with deref type.
    // Local arrays (e.g. void* slots[8]) must use the fallback — their deref_type is wrong
    // (it includes the array dimension) and they don't need a load since the alloca IS the base.
    {
        LLVMValueRef local_alloca = oname.empty() ? nullptr : ctx->lookup_local(oname);
        bool is_local_array = local_alloca && LLVMIsAAllocaInst(local_alloca)
            && LLVMGetTypeKind(LLVMGetAllocatedType(local_alloca)) == LLVMArrayTypeKind;
        LLVMTypeRef dt = (!oname.empty() && !is_local_array) ? ctx->lookup_deref_type(oname) : nullptr;
        if (dt) {
            LLVMValueRef base = visit_expr(e->object, ctx); // loads the pointer value
            elem_t_out = dt;
            return LLVMBuildGEP2(ctx->llvm_builder, dt, base, &idx, 1, "elemptr");
        }
    }

    // Member-field array/pointer base (e.g. self.arr_field[i] or self.ptr_field[i]):
    // look up the field's LLVM type so we can emit correct subscript IR.
    if (e->object->kind == expr_kind::member && !e->object->member_name.empty()) {
        std::string pname = infer_struct_tname(e->object->object, ctx);
        auto nfit = ctx->struct_field_names.find(pname);
        auto tfit = ctx->struct_field_types.find(pname);
        if (nfit != ctx->struct_field_names.end() && tfit != ctx->struct_field_types.end()) {
            const auto& fnames = nfit->second;
            const auto& ftypes = tfit->second;
            for (unsigned i = 0; i < fnames.size(); i++) {
                if (fnames[i] == e->object->member_name && i < ftypes.size()) {
                    LLVMTypeRef field_t = ftypes[i];
                    if (field_t && LLVMGetTypeKind(field_t) == LLVMArrayTypeKind) {
                        LLVMTypeRef elem_t = LLVMGetElementType(field_t);
                        LLVMValueRef base_ptr = visit_lvalue(e->object, ctx);
                        LLVMValueRef indices[2] = {
                            LLVMConstInt(LLVMInt32TypeInContext(ctx->llvm_ctx), 0, 0), idx
                        };
                        elem_t_out = elem_t;
                        return LLVMBuildGEP2(ctx->llvm_builder, field_t, base_ptr, indices, 2, "elemptr");
                    } else if (field_t && LLVMGetTypeKind(field_t) == LLVMPointerTypeKind) {
                        // Pointer field: load pointer value then GEP by index.
                        // Use stored pointee type for correct element type (e.g. T* -> T).
                        LLVMValueRef field_addr = visit_lvalue(e->object, ctx);
                        LLVMValueRef base = LLVMBuildLoad2(ctx->llvm_builder, field_t, field_addr, "ptrload");
                        LLVMTypeRef elem_t = nullptr;
                        auto pit = ctx->struct_field_pointee_types.find(pname);
                        if (pit != ctx->struct_field_pointee_types.end() && i < pit->second.size())
                            elem_t = pit->second[i];
                        if (!elem_t) elem_t = LLVMPointerTypeInContext(ctx->llvm_ctx, 0);
                        elem_t_out = elem_t;
                        return LLVMBuildGEP2(ctx->llvm_builder, elem_t, base, &idx, 1, "elemptr");
                    }
                    break;
                }
            }
        }
    }

    // Array (or fallback) base: index from the aggregate's address.
    // Non-identifier object (e.g. cast or call expression): evaluate as rvalue pointer.
    if (oname.empty()) {
        LLVMValueRef base = visit_expr(e->object, ctx);
        LLVMTypeRef elem_t = LLVMInt8TypeInContext(ctx->llvm_ctx);
        if (e->object->kind == expr_kind::cast && e->object->cast_type
            && e->object->cast_type->pointer_depth > 0) {
            type_node tmp = *e->object->cast_type;
            tmp.pointer_depth -= 1;
            tmp.array_size.reset();
            elem_t = llvm_type_of(&tmp, ctx);
        }
        elem_t_out = elem_t;
        return LLVMBuildGEP2(ctx->llvm_builder, elem_t, base, &idx, 1, "elemptr");
    }
    LLVMValueRef base_ptr = visit_lvalue(e->object, ctx);
    LLVMTypeRef  elem_t   = ctx->lookup_local_type(oname);
    if (!elem_t) elem_t = LLVMInt8TypeInContext(ctx->llvm_ctx);
    elem_t_out = elem_t;
    return LLVMBuildGEP2(ctx->llvm_builder, elem_t, base_ptr, &idx, 1, "elemptr");
}

inline LLVMValueRef visit_subscript_expr(expr_node* e, ir_context* ctx) {
    // Runtime bounds check for UNKNOWN sites from SMT.
    if (ctx->unsafe_ops.count(e)) {
        LLVMValueRef idx = visit_expr(e->index, ctx);
        const std::string oname = e->object && e->object->kind == expr_kind::identifier
                                  ? e->object->str_val : "";
        LLVMTypeRef arr_t = oname.empty() ? nullptr : ctx->lookup_local_type(oname);
        LLVMValueRef cond_ok = nullptr;
        if (arr_t && LLVMGetTypeKind(arr_t) == LLVMArrayTypeKind) {
            unsigned sz   = LLVMGetArrayLength(arr_t);
            LLVMTypeRef t = LLVMTypeOf(idx);
            LLVMValueRef sz_v = LLVMConstInt(t, sz, 0);
            // ult: unsigned less-than — covers both negative (wraps to huge) and ≥sz
            cond_ok = LLVMBuildICmp(ctx->llvm_builder, LLVMIntULT, idx, sz_v, "bchk");
        } else {
            // Dynamic array: only check idx is non-negative (signed)
            LLVMValueRef zero = LLVMConstInt(LLVMTypeOf(idx), 0, 0);
            cond_ok = LLVMBuildICmp(ctx->llvm_builder, LLVMIntSGE, idx, zero, "bchk");
        }
        if (cond_ok) emit_rt_check(e, cond_ok, ctx);
    }
    LLVMTypeRef elem_t = nullptr;
    LLVMValueRef gep = subscript_elem_ptr(e, ctx, elem_t);
    return LLVMBuildLoad2(ctx->llvm_builder, elem_t, gep, "elem");
}

// ------------------------------------------------------------------ member

inline LLVMValueRef visit_member_expr(expr_node* e, ir_context* ctx) {
    // EnumName::VariantName — works for both plain enums and ADT enums.
    // Must be an unqualified identifier not shadowed by a local variable.
    if (e->object->kind == expr_kind::identifier && !ctx->lookup_local(e->object->str_val)) {
        const std::string& obj = e->object->str_val;
        // Plain C-style enum: global stored under "EnumName::VariantName"
        std::string plain_key = obj + "::" + e->member_name;
        auto pit = ctx->global_vars.find(plain_key);
        if (pit != ctx->global_vars.end()) {
            LLVMValueRef init = LLVMGetInitializer(pit->second);
            if (init) return init;
            return LLVMBuildLoad2(ctx->llvm_builder,
                LLVMInt32TypeInContext(ctx->llvm_ctx), pit->second, "enumval");
        }
        // ADT enum plain variant: build a full ADT struct value {tag, zeroed payload}
        auto adt_it = ctx->adt_enums.find(obj);
        if (adt_it != ctx->adt_enums.end()) {
            std::string tag_key = plain_key + "__tag";
            auto tit = ctx->global_vars.find(tag_key);
            if (tit != ctx->global_vars.end()) {
                LLVMValueRef tag_i32 = LLVMGetInitializer(tit->second);
                if (!tag_i32) tag_i32 = LLVMBuildLoad2(ctx->llvm_builder,
                    LLVMInt32TypeInContext(ctx->llvm_ctx), tit->second, "adttag");
                // Build full struct value: {tag, zero_payload}
                auto stype_it = ctx->struct_types.find(obj);
                if (stype_it != ctx->struct_types.end()) {
                    LLVMTypeRef adt_t = stype_it->second;
                    LLVMValueRef tmp = LLVMBuildAlloca(ctx->llvm_builder, adt_t, "adttmp");
                    LLVMValueRef tp  = LLVMBuildStructGEP2(ctx->llvm_builder, adt_t, tmp, 0, "tp");
                    LLVMBuildStore(ctx->llvm_builder, tag_i32, tp);
                    if (LLVMCountStructElementTypes(adt_t) > 1) {
                        LLVMValueRef pp = LLVMBuildStructGEP2(ctx->llvm_builder, adt_t, tmp, 1, "pp");
                        LLVMBuildStore(ctx->llvm_builder, LLVMConstNull(LLVMStructGetTypeAtIndex(adt_t, 1)), pp);
                    }
                    return LLVMBuildLoad2(ctx->llvm_builder, adt_t, tmp, "adtval");
                }
                return tag_i32; // fallback: plain enum without struct type
            }
        }
    }

    // ADT enum payload field load: (*x).field — determine correct field type from enum def.
    if (e->object->kind == expr_kind::unary && e->object->uop == unary_op::deref &&
        e->object->operand->kind == expr_kind::identifier) {
        const std::string& xname = e->object->operand->str_val;
        LLVMTypeRef local_t = ctx->lookup_local_type(xname);
        if (local_t && LLVMGetTypeKind(local_t) == LLVMStructTypeKind) {
            const char* sn = LLVMGetStructName(local_t);
            if (sn && ctx->adt_enums.count(sn)) {
                enum_decl* ed = ctx->adt_enums.at(sn);
                // Search all variant fields for the member name
                for (auto* ev : ed->variants) {
                    for (auto* sf : ev->struct_fields) {
                        if (sf->name == e->member_name) {
                            LLVMTypeRef field_t = llvm_type_of(sf->type, ctx);
                            LLVMValueRef fp = visit_lvalue(e, ctx);
                            return LLVMBuildLoad2(ctx->llvm_builder, field_t, fp, e->member_name.c_str());
                        }
                    }
                    if (ev->istruc_body) {
                        for (auto* cf : ev->istruc_body->fields) {
                            if (cf->name == e->member_name) {
                                LLVMTypeRef field_t = llvm_type_of(cf->type, ctx);
                                LLVMValueRef fp = visit_lvalue(e, ctx);
                                return LLVMBuildLoad2(ctx->llvm_builder, field_t, fp, e->member_name.c_str());
                            }
                        }
                    }
                }
            }
        }
    }

    // visit_lvalue handles the GEP; we load the correct field type via struct_field_types.
    LLVMValueRef field_ptr = visit_lvalue(e, ctx);

    std::string tname;
    if (e->object->kind == expr_kind::identifier) {
        LLVMTypeRef elem = ctx->lookup_local_type(e->object->str_val);
        if (elem && LLVMGetTypeKind(elem) == LLVMStructTypeKind)
            tname = LLVMGetStructName(elem) ? LLVMGetStructName(elem) : "";
        if (tname.empty()) {
            LLVMTypeRef deref_t = ctx->lookup_deref_type(e->object->str_val);
            if (deref_t && LLVMGetTypeKind(deref_t) == LLVMStructTypeKind)
                tname = LLVMGetStructName(deref_t) ? LLVMGetStructName(deref_t) : "";
        }
    } else if (e->object->kind == expr_kind::unary &&
               e->object->uop == unary_op::deref &&
               e->object->operand->kind == expr_kind::identifier) {
        LLVMTypeRef deref_t = ctx->lookup_deref_type(e->object->operand->str_val);
        if (deref_t && LLVMGetTypeKind(deref_t) == LLVMStructTypeKind)
            tname = LLVMGetStructName(deref_t) ? LLVMGetStructName(deref_t) : "";
    }
    if (tname.empty())
        tname = infer_struct_tname(e->object, ctx);

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
    // Check for a conversion operator: if operand is a struct, look for ClassName__MT_operator T.
    if (e->operand->kind == expr_kind::identifier) {
        LLVMTypeRef src_local = ctx->lookup_local_type(e->operand->str_val);
        if (src_local && LLVMGetTypeKind(src_local) == LLVMStructTypeKind) {
            const char* sname = LLVMGetStructName(src_local);
            if (sname) {
                LLVMTypeRef dst_t_check = llvm_type_of(e->cast_type, ctx);
                // Build the conversion operator function name: ClassName__MT_operator <type_str>
                // Try by looking for any ClassName__MT_operator* whose return type matches dst_t.
                std::string prefix = std::string(sname) + "__MT_operator";
                for (auto& [fname, fval] : ctx->global_funcs) {
                    if (fname.rfind(prefix, 0) == 0) {  // starts with prefix
                        LLVMTypeRef fn_t = ctx->global_func_types[fname];
                        LLVMTypeRef ret_t = LLVMGetReturnType(fn_t);
                        if (ret_t == dst_t_check) {
                            LLVMValueRef self_ptr = visit_lvalue(e->operand, ctx);
                            return LLVMBuildCall2(ctx->llvm_builder, fn_t, fval,
                                                  &self_ptr, 1, "convop");
                        }
                    }
                }
            }
        }
    }

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
    if (e->cast_type) {
        measured_t = llvm_type_of(e->cast_type, ctx);
    } else if (e->operand && e->operand->kind == expr_kind::identifier
               && ctx->type_subst.count(e->operand->str_val)) {
        // sizeof(T) in a generic body — T is a type parameter, not a value
        measured_t = ctx->type_subst.at(e->operand->str_val);
    } else {
        measured_t = LLVMTypeOf(visit_expr(e->operand, ctx));
    }

    // LLVMSizeOf returns an i64 constant for the target data layout size.
    return LLVMSizeOf(measured_t);
}

// ------------------------------------------------------------------ ?? null coalescing

inline LLVMValueRef visit_null_coal_expr(expr_node* e, ir_context* ctx) {
    LLVMValueRef lhs_val = visit_expr(e->lhs, ctx);
    LLVMTypeRef  lhs_t   = LLVMTypeOf(lhs_val);

    // Build null/zero check → i1 "is present"
    LLVMValueRef cond_val;
    if (llvm_is_float(lhs_t)) {
        cond_val = LLVMBuildFCmp(ctx->llvm_builder, LLVMRealONE,
                                  lhs_val, LLVMConstNull(lhs_t), "coal_cond");
    } else {
        cond_val = LLVMBuildICmp(ctx->llvm_builder, LLVMIntNE,
                                  lhs_val, LLVMConstNull(lhs_t), "coal_cond");
    }

    LLVMValueRef      fn         = ctx->current_func;
    LLVMBasicBlockRef present_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "coal_present");
    LLVMBasicBlockRef absent_bb  = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "coal_absent");
    LLVMBasicBlockRef merge_bb   = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "coal_merge");

    LLVMBuildCondBr(ctx->llvm_builder, cond_val, present_bb, absent_bb);

    // Present branch: yield lhs_val unchanged
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, present_bb);
    LLVMBasicBlockRef present_exit = present_bb;
    if (!ctx->is_terminated()) {
        present_exit = LLVMGetInsertBlock(ctx->llvm_builder);
        LLVMBuildBr(ctx->llvm_builder, merge_bb);
    }

    // Absent branch: evaluate RHS or execute block
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, absent_bb);
    LLVMValueRef absent_val = LLVMConstNull(lhs_t); // default if block terminates
    if (e->rhs) {
        absent_val = visit_expr(e->rhs, ctx);
    } else if (e->handler_block) {
        visit_block_stmt(e->handler_block, ctx);
        // Block may terminate (panic/return). If not, use null/zero as placeholder.
    }
    LLVMBasicBlockRef absent_exit = LLVMGetInsertBlock(ctx->llvm_builder);
    bool absent_reaches = !ctx->is_terminated();
    if (absent_reaches) LLVMBuildBr(ctx->llvm_builder, merge_bb);

    // Merge: phi if both paths reach here, otherwise just use lhs_val
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, merge_bb);
    if (absent_reaches) {
        LLVMValueRef phi = LLVMBuildPhi(ctx->llvm_builder, lhs_t, "coal_val");
        LLVMValueRef vals[2]           = {lhs_val,    absent_val};
        LLVMBasicBlockRef bbs[2]       = {present_exit, absent_exit};
        LLVMAddIncoming(phi, vals, bbs, 2);
        return phi;
    }
    return lhs_val;
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

// ------------------------------------------------------------------ class initializer

// Emit field stores for a class_init expression into an already-allocated struct pointer.
// `struct_t` is the LLVM struct type and `tname` its registered name.
inline void emit_class_init_into(expr_node* e, LLVMValueRef dest_ptr,
                                 LLVMTypeRef struct_t, const std::string& tname,
                                 ir_context* ctx) {
    // Zero-initialise first.
    LLVMBuildStore(ctx->llvm_builder, LLVMConstNull(struct_t), dest_ptr);

    auto fnit = ctx->struct_field_names.find(tname);
    if (fnit == ctx->struct_field_names.end()) return;
    const auto& fnames = fnit->second;
    LLVMTypeRef i32 = LLVMInt32TypeInContext(ctx->llvm_ctx);

    for (auto& [fname, val_expr] : e->field_inits) {
        for (unsigned fi = 0; fi < fnames.size(); ++fi) {
            if (fnames[fi] == fname) {
                LLVMValueRef idx[2] = { LLVMConstInt(i32, 0, 0), LLVMConstInt(i32, fi, 0) };
                LLVMValueRef fptr = LLVMBuildGEP2(ctx->llvm_builder, struct_t, dest_ptr, idx, 2, "ci.field");
                LLVMValueRef v = visit_expr(val_expr, ctx);
                LLVMTypeRef ft = LLVMStructGetTypeAtIndex(struct_t, fi);
                v = coerce_int_val(v, ft, ctx->llvm_builder);
                LLVMBuildStore(ctx->llvm_builder, v, fptr);
                break;
            }
        }
    }
}

inline LLVMValueRef visit_class_init(expr_node* e, ir_context* ctx) {
    // ADT enum variant init: EnumName::VariantName { .field = val } (named-struct or istruc)
    // or: EnumName::VariantName .{ .field = val } (istruc via context-inferred .{...})
    // Detected when e->object is a member expr whose object is a known ADT enum type.
    if (e->object && e->object->kind == expr_kind::member &&
        e->object->object && e->object->object->kind == expr_kind::identifier) {
        const std::string& enum_name    = e->object->object->str_val;
        const std::string& variant_name = e->object->member_name;
        auto adt_it = ctx->adt_enums.find(enum_name);
        if (adt_it != ctx->adt_enums.end()) {
            enum_decl* ed = adt_it->second;
            LLVMTypeRef adt_t = ctx->struct_types[enum_name];
            LLVMTypeRef i32t  = LLVMInt32TypeInContext(ctx->llvm_ctx);
            LLVMTypeRef i8t   = LLVMInt8TypeInContext(ctx->llvm_ctx);

            // Find the variant and its tag
            int tag_val = 0;
            enum_variant* found_ev = nullptr;
            for (auto* ev : ed->variants) {
                if (ev->name == variant_name) { found_ev = ev; break; }
                tag_val++;
            }

            LLVMValueRef alloca = LLVMBuildAlloca(ctx->llvm_builder, adt_t, "adt.tmp");
            LLVMBuildStore(ctx->llvm_builder, LLVMConstNull(adt_t), alloca);
            // Store tag
            LLVMValueRef tag_ptr = LLVMBuildStructGEP2(ctx->llvm_builder, adt_t, alloca, 0, "tagp");
            LLVMBuildStore(ctx->llvm_builder, LLVMConstInt(i32t, tag_val, 0), tag_ptr);

            // Store named fields into payload (named_struct or istruc_body variants)
            bool has_payload_fields = found_ev &&
                ((!found_ev->struct_fields.empty()) ||
                 (found_ev->istruc_body && !found_ev->istruc_body->fields.empty()));
            if (has_payload_fields) {
                LLVMValueRef payload_ptr = LLVMBuildStructGEP2(ctx->llvm_builder, adt_t, alloca, 1, "payp");
                // Build byte-offset map for fields
                std::unordered_map<std::string, std::pair<unsigned, LLVMTypeRef>> field_map;
                unsigned byte_off = 0;
                // named_struct fields
                for (auto* sf : found_ev->struct_fields) {
                    LLVMTypeRef ft = llvm_type_of(sf->type, ctx);
                    field_map[sf->name] = {byte_off, ft};
                    byte_off += adt_type_byte_size(ft, ctx);
                }
                // istruc_body fields
                if (found_ev->istruc_body) {
                    for (auto* cf : found_ev->istruc_body->fields) {
                        LLVMTypeRef ft = llvm_type_of(cf->type, ctx);
                        field_map[cf->name] = {byte_off, ft};
                        byte_off += adt_type_byte_size(ft, ctx);
                    }
                }
                for (auto& [fname, val_expr] : e->field_inits) {
                    auto ffit = field_map.find(fname);
                    if (ffit == field_map.end()) continue;
                    LLVMValueRef v = visit_expr(val_expr, ctx);
                    v = coerce_int_val(v, ffit->second.second, ctx->llvm_builder);
                    LLVMValueRef zero  = LLVMConstInt(i32t, 0, 0);
                    LLVMValueRef off_v = LLVMConstInt(i32t, ffit->second.first, 0);
                    LLVMValueRef bidx[2] = {zero, off_v};
                    LLVMValueRef bp = LLVMBuildGEP2(ctx->llvm_builder,
                        LLVMArrayType(i8t, 1), payload_ptr, bidx, 2, "byteptr");
                    LLVMValueRef fp = LLVMBuildBitCast(ctx->llvm_builder, bp,
                        LLVMPointerType(ffit->second.second, 0), "fptr");
                    LLVMBuildStore(ctx->llvm_builder, v, fp);
                }
            }
            return LLVMBuildLoad2(ctx->llvm_builder, adt_t, alloca, "adtval");
        }
    }

    // Standard class initializer
    std::string tname;
    if (e->init_type && e->init_type->name) tname = *e->init_type->name;
    auto it = ctx->struct_types.find(tname);
    if (it == ctx->struct_types.end())
        throw std::runtime_error("IR: class initializer for unknown type '" + tname + "'");
    LLVMTypeRef struct_t = it->second;
    LLVMValueRef tmp = LLVMBuildAlloca(ctx->llvm_builder, struct_t, "ci.tmp");
    emit_class_init_into(e, tmp, struct_t, tname, ctx);
    return LLVMBuildLoad2(ctx->llvm_builder, struct_t, tmp, "ci.val");
}

// ------------------------------------------------------------------ error_t helpers

// Return (or create) the { i32 code, i8* name } LLVM struct type for error_t.
// Also registers field metadata so member-access IR works on error_t variables.
inline LLVMTypeRef get_error_t_type(ir_context* ctx) {
    static const char* kName = "error_t";
    LLVMTypeRef existing = LLVMGetTypeByName2(ctx->llvm_ctx, kName);
    if (existing) return existing;

    LLVMTypeRef i32t  = LLVMInt32TypeInContext(ctx->llvm_ctx);
    LLVMTypeRef i8pt  = LLVMPointerType(LLVMInt8TypeInContext(ctx->llvm_ctx), 0);
    LLVMTypeRef fields[3] = { i32t, i8pt, i8pt };
    LLVMTypeRef st = LLVMStructCreateNamed(ctx->llvm_ctx, kName);
    LLVMStructSetBody(st, fields, 3, 0);

    // Register field metadata for member access (e.code, e.name, e.payload)
    ctx->struct_field_names[kName] = { "code", "name", "payload" };
    ctx->struct_field_types[kName] = { i32t, i8pt, i8pt };
    ctx->struct_field_unsigned[kName] = { false, false, false };
    ctx->struct_types[kName] = st;
    return st;
}

// Emit (once per module) the i8* __artemis_error_name(i32 code) lookup function.
inline void ensure_error_name_fn(ir_context* ctx) {
    if (ctx->error_name_fn_emitted) return;
    ctx->error_name_fn_emitted = true;

    LLVMTypeRef i32t  = LLVMInt32TypeInContext(ctx->llvm_ctx);
    LLVMTypeRef i8pt  = LLVMPointerType(LLVMInt8TypeInContext(ctx->llvm_ctx), 0);
    LLVMTypeRef fn_t  = LLVMFunctionType(i8pt, &i32t, 1, 0);
    LLVMValueRef fn   = LLVMAddFunction(ctx->llvm_mod, "__artemis_error_name", fn_t);
    LLVMSetLinkage(fn, LLVMPrivateLinkage);

    LLVMBuilderRef bld = LLVMCreateBuilderInContext(ctx->llvm_ctx);
    LLVMBasicBlockRef entry = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "entry");
    LLVMPositionBuilderAtEnd(bld, entry);

    LLVMValueRef param = LLVMGetParam(fn, 0);

    // One branch per registered error name; fall through to "?" return.
    const auto& reg = ctx->error_registry;
    LLVMBasicBlockRef done_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "err_done");

    // Emit a series of: if (code == hash) return "Name";
    for (const auto& [hash, name] : reg) {
        // Create a private constant for the name string
        std::string gname = "__artemis_errstr_" + name;
        LLVMValueRef existing_str = LLVMGetNamedGlobal(ctx->llvm_mod, gname.c_str());
        if (!existing_str) {
            LLVMValueRef cs = LLVMConstStringInContext(ctx->llvm_ctx,
                                                       name.c_str(), (unsigned)name.size(), 0);
            existing_str = LLVMAddGlobal(ctx->llvm_mod, LLVMTypeOf(cs), gname.c_str());
            LLVMSetInitializer(existing_str, cs);
            LLVMSetGlobalConstant(existing_str, 1);
            LLVMSetLinkage(existing_str, LLVMPrivateLinkage);
        }

        LLVMBasicBlockRef match_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "err_match");
        LLVMBasicBlockRef next_bb  = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "err_next");
        LLVMValueRef cmp = LLVMBuildICmp(bld, LLVMIntEQ, param,
                                          LLVMConstInt(i32t, hash, 0), "eq");
        LLVMBuildCondBr(bld, cmp, match_bb, next_bb);

        LLVMPositionBuilderAtEnd(bld, match_bb);
        // Return GEP to first char of the string constant
        LLVMTypeRef arr_t = LLVMTypeOf(LLVMGetInitializer(existing_str));
        LLVMValueRef zero = LLVMConstInt(LLVMInt32TypeInContext(ctx->llvm_ctx), 0, 0);
        LLVMValueRef idxs[2] = { zero, zero };
        LLVMValueRef sptr = LLVMBuildGEP2(bld, arr_t, existing_str, idxs, 2, "sptr");
        LLVMBuildRet(bld, sptr);

        LLVMPositionBuilderAtEnd(bld, next_bb);
    }
    // Fallback: return "?"
    {
        std::string uname = "__artemis_errstr_unknown";
        LLVMValueRef unk = LLVMGetNamedGlobal(ctx->llvm_mod, uname.c_str());
        if (!unk) {
            LLVMValueRef cs = LLVMConstStringInContext(ctx->llvm_ctx, "?", 1, 0);
            unk = LLVMAddGlobal(ctx->llvm_mod, LLVMTypeOf(cs), uname.c_str());
            LLVMSetInitializer(unk, cs);
            LLVMSetGlobalConstant(unk, 1);
            LLVMSetLinkage(unk, LLVMPrivateLinkage);
        }
        LLVMTypeRef arr_t = LLVMTypeOf(LLVMGetInitializer(unk));
        LLVMValueRef zero = LLVMConstInt(LLVMInt32TypeInContext(ctx->llvm_ctx), 0, 0);
        LLVMValueRef idxs[2] = { zero, zero };
        LLVMValueRef sptr = LLVMBuildGEP2(bld, arr_t, unk, idxs, 2, "sptr");
        LLVMBuildRet(bld, sptr);
    }

    // done_bb is unreachable but needed to satisfy LLVM — connect it
    LLVMPositionBuilderAtEnd(bld, done_bb);
    LLVMBuildRet(bld, LLVMConstNull(i8pt));

    LLVMDisposeBuilder(bld);

    // Register in global_funcs so call-sites can find it
    ctx->global_funcs["__artemis_error_name"] = fn;
    ctx->global_func_types["__artemis_error_name"] = fn_t;
}

// ------------------------------------------------------------------ error_lit  (error.Name -> i32)

inline LLVMValueRef visit_error_lit_expr(expr_node* e, ir_context* ctx) {
    // FNV-1a 32-bit hash of the error name string
    uint32_t h = 2166136261u;
    for (unsigned char c : e->str_val) { h ^= c; h *= 16777619u; }
    if (h == 0) h = 1; // 0 is reserved for "no error"

    // Register name for __artemis_error_name() lookup (deduplicated)
    bool found = false;
    for (const auto& [hh, nn] : ctx->error_registry)
        if (hh == h) { found = true; break; }
    if (!found) ctx->error_registry.push_back({h, e->str_val});

    return LLVMConstInt(LLVMInt32TypeInContext(ctx->llvm_ctx),
                        static_cast<unsigned long long>(h), 0);
}

// ------------------------------------------------------------------ try expr  (propagate error union)

inline LLVMValueRef visit_try_expr_func(expr_node* e, ir_context* ctx) {
    LLVMValueRef result   = visit_expr(e->operand, ctx);
    LLVMTypeRef  result_t = LLVMTypeOf(result);
    LLVMTypeRef  i32t     = LLVMInt32TypeInContext(ctx->llvm_ctx);

    if (LLVMGetTypeKind(result_t) != LLVMStructTypeKind ||
        LLVMCountStructElementTypes(result_t) < 1)
        return result; // not an error-union; pass through

    LLVMValueRef err_tag = LLVMBuildExtractValue(ctx->llvm_builder, result, 0, "eu_tag");
    LLVMValueRef is_err  = LLVMBuildICmp(ctx->llvm_builder, LLVMIntNE,
                                          err_tag, LLVMConstInt(i32t, 0, 0), "is_err");

    LLVMValueRef fn = ctx->current_func;
    LLVMBasicBlockRef err_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "try_err");
    LLVMBasicBlockRef ok_bb  = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "try_ok");
    LLVMBuildCondBr(ctx->llvm_builder, is_err, err_bb, ok_bb);

    // Error path: propagate to caller (propagate tag + payload)
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, err_bb);
    if (ctx->current_func_is_error_union && ctx->current_error_union_type) {
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

    // Ok path: yield the value (field 2 for !T, void for !void/2-field)
    LLVMPositionBuilderAtEnd(ctx->llvm_builder, ok_bb);
    if (LLVMCountStructElementTypes(result_t) >= 3)
        return LLVMBuildExtractValue(ctx->llvm_builder, result, 2, "eu_val");
    return LLVMConstInt(i32t, 0, 0); // !void success
}

// ------------------------------------------------------------------ except expr  (call() except |e| {})

inline LLVMValueRef visit_except_expr_func(expr_node* e, ir_context* ctx) {
    LLVMValueRef result   = visit_expr(e->object, ctx);
    LLVMTypeRef  result_t = LLVMTypeOf(result);
    LLVMTypeRef  i32t     = LLVMInt32TypeInContext(ctx->llvm_ctx);

    if (LLVMGetTypeKind(result_t) == LLVMStructTypeKind &&
        LLVMCountStructElementTypes(result_t) >= 1) {
        LLVMValueRef err_tag = LLVMBuildExtractValue(ctx->llvm_builder, result, 0, "eu_tag");
        LLVMValueRef is_err  = LLVMBuildICmp(ctx->llvm_builder, LLVMIntNE,
                                              err_tag, LLVMConstInt(i32t, 0, 0), "is_err");

        LLVMValueRef fn = ctx->current_func;
        LLVMBasicBlockRef handler_bb = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "except");
        LLVMBasicBlockRef after_bb   = LLVMAppendBasicBlockInContext(ctx->llvm_ctx, fn, "after_exc");
        LLVMBuildCondBr(ctx->llvm_builder, is_err, handler_bb, after_bb);

        LLVMPositionBuilderAtEnd(ctx->llvm_builder, handler_bb);
        ctx->push_scope();
        if (!e->str_val.empty()) {
            // Bind the error binding as error_t {code: i32, name: i8*, payload: i8*}
            ensure_error_name_fn(ctx);
            LLVMTypeRef et    = get_error_t_type(ctx);
            LLVMTypeRef i8pt  = LLVMPointerType(LLVMInt8TypeInContext(ctx->llvm_ctx), 0);
            LLVMValueRef err_alloca = LLVMBuildAlloca(ctx->llvm_builder, et, e->str_val.c_str());
            LLVMValueRef code_ptr    = LLVMBuildStructGEP2(ctx->llvm_builder, et, err_alloca, 0, "et_code");
            LLVMValueRef name_ptr    = LLVMBuildStructGEP2(ctx->llvm_builder, et, err_alloca, 1, "et_name");
            LLVMValueRef payload_ptr = LLVMBuildStructGEP2(ctx->llvm_builder, et, err_alloca, 2, "et_payload");
            LLVMBuildStore(ctx->llvm_builder, err_tag, code_ptr);
            LLVMValueRef lookup_fn = ctx->global_funcs.count("__artemis_error_name")
                ? ctx->global_funcs["__artemis_error_name"] : nullptr;
            LLVMTypeRef  lookup_ft = ctx->global_func_types.count("__artemis_error_name")
                ? ctx->global_func_types["__artemis_error_name"] : nullptr;
            if (lookup_fn && lookup_ft) {
                LLVMValueRef name_val = LLVMBuildCall2(ctx->llvm_builder, lookup_ft, lookup_fn,
                                                        &err_tag, 1, "et_name_val");
                LLVMBuildStore(ctx->llvm_builder, name_val, name_ptr);
            } else {
                LLVMBuildStore(ctx->llvm_builder, LLVMConstNull(i8pt), name_ptr);
            }
            // Store payload from error union field 1 (if present)
            LLVMValueRef payload_val = LLVMCountStructElementTypes(result_t) >= 2
                ? LLVMBuildExtractValue(ctx->llvm_builder, result, 1, "eu_payload_v")
                : LLVMConstNull(i8pt);
            LLVMBuildStore(ctx->llvm_builder, payload_val, payload_ptr);
            ctx->declare_local(e->str_val, err_alloca, et);
        }
        // Optional override binding: bool, true when error is a UB-injected check
        if (!e->member_name.empty()) {
            LLVMTypeRef i1t = LLVMInt1TypeInContext(ctx->llvm_ctx);
            LLVMTypeRef i32t2 = LLVMInt32TypeInContext(ctx->llvm_ctx);
            // UB error codes: fnv32 of "mm.out_of_bounds", "mm.null_deref", "mm.div_zero"
            static const uint32_t ub_codes[] = {
                fnv32_str("mm.out_of_bounds"),
                fnv32_str("mm.null_deref"),
                fnv32_str("mm.div_zero"),
            };
            // is_ub = (err_tag == code1) | (err_tag == code2) | (err_tag == code3)
            LLVMValueRef is_ub = LLVMConstInt(i1t, 0, 0);
            for (uint32_t code : ub_codes) {
                LLVMValueRef eq = LLVMBuildICmp(ctx->llvm_builder, LLVMIntEQ,
                    err_tag, LLVMConstInt(i32t2, code, 0), "ub_eq");
                is_ub = LLVMBuildOr(ctx->llvm_builder, is_ub, eq, "ub_or");
            }
            LLVMValueRef ov_alloca = LLVMBuildAlloca(ctx->llvm_builder, i1t, e->member_name.c_str());
            LLVMBuildStore(ctx->llvm_builder, is_ub, ov_alloca);
            ctx->declare_local(e->member_name, ov_alloca, i1t);
        }
        if (e->handler_block) visit_block_stmt(e->handler_block, ctx);
        ctx->pop_scope();
        if (!ctx->is_terminated()) LLVMBuildBr(ctx->llvm_builder, after_bb);

        LLVMPositionBuilderAtEnd(ctx->llvm_builder, after_bb);
        // ok_value is at field 2 in {i32 tag, i8* payload, T ok}
        if (LLVMCountStructElementTypes(result_t) >= 3)
            return LLVMBuildExtractValue(ctx->llvm_builder, result, 2, "eu_val");
        return LLVMConstInt(i32t, 0, 0);
    }

    // Not an error-union expression: run handler unconditionally and return result
    if (e->handler_block) {
        ctx->push_scope();
        visit_block_stmt(e->handler_block, ctx);
        ctx->pop_scope();
    }
    return result;
}

// ------------------------------------------------------------------ get_ifo_t  (compile-time reflection)

// Return the canonical name of a type_node (handles pointer decoration inline).
inline std::string ifo_type_name(const type_node* t) {
    if (!t) return "void";
    if (t->pointer_depth > 0) {
        type_node base = *t; base.pointer_depth = 0;
        std::string s = ifo_type_name(&base);
        for (int i = 0; i < t->pointer_depth; i++) s += "*";
        return s;
    }
    if (!t->is_primitive) return t->name.value_or("<unknown>");
    switch (t->prim.value()) {
        case prim_type_t::char_t:    return "char";
        case prim_type_t::arb_int:   return "i" + std::to_string(t->bit_width);
        case prim_type_t::arb_uint:  return "u" + std::to_string(t->bit_width);
        case prim_type_t::arb_float: return "f" + std::to_string(t->bit_width);
        case prim_type_t::arb_bool:  return "b" + std::to_string(t->bit_width);
        case prim_type_t::void_t:    return "void";
        default:                     return "<prim>";
    }
}

// Get or create the ifo_t struct LLVM type in this context.
// Layout mirrors ifo.arc:ifo::ifo_t:
//   { i8*, i32, i32, i32, i32, i32, i32, i8*, i8*, i32, i8* }
//   { name, size, align, kind, bits, is_signed, field_count, fields*, elem_type*, method_count, methods* }
inline LLVMTypeRef get_ifo_t_llvm_type(ir_context* ctx) {
    const char* IFO_STRUCT = "std__NS_ifo__NS_ifo_t";
    auto it = ctx->struct_types.find(IFO_STRUCT);
    if (it != ctx->struct_types.end()) return it->second;

    LLVMContextRef lctx = ctx->llvm_ctx;
    LLVMTypeRef i8pt = LLVMPointerType(LLVMInt8TypeInContext(lctx), 0);
    LLVMTypeRef i32t = LLVMInt32TypeInContext(lctx);
    LLVMTypeRef f[11] = { i8pt, i32t, i32t, i32t, i32t, i32t, i32t, i8pt, i8pt, i32t, i8pt };
    LLVMTypeRef t = LLVMStructCreateNamed(lctx, IFO_STRUCT);
    LLVMStructSetBody(t, f, 11, 0);
    ctx->struct_types[IFO_STRUCT] = t;
    return t;
}

// Get or create the ifo_method_t struct LLVM type.
// Layout: { i8* name, i32 param_count, i32 ret_size }
inline LLVMTypeRef get_ifo_method_t_llvm_type(ir_context* ctx) {
    const char* NAME = "std__NS_ifo__NS_ifo_method_t";
    auto it = ctx->struct_types.find(NAME);
    if (it != ctx->struct_types.end()) return it->second;
    LLVMContextRef lctx = ctx->llvm_ctx;
    LLVMTypeRef i8pt = LLVMPointerType(LLVMInt8TypeInContext(lctx), 0);
    LLVMTypeRef i32t = LLVMInt32TypeInContext(lctx);
    LLVMTypeRef mfields[3] = { i8pt, i32t, i32t };
    LLVMTypeRef t = LLVMStructCreateNamed(lctx, NAME);
    LLVMStructSetBody(t, mfields, 3, 0);
    ctx->struct_types[NAME] = t;
    return t;
}

// Return byte size of an LLVM type (conservative — no target data needed).
static unsigned ifo_llvm_sizeof(LLVMTypeRef t) {
    switch (LLVMGetTypeKind(t)) {
        case LLVMIntegerTypeKind: return (LLVMGetIntTypeWidth(t) + 7) / 8;
        case LLVMPointerTypeKind: return 8;
        case LLVMHalfTypeKind:    return 2;
        case LLVMFloatTypeKind:   return 4;
        case LLVMDoubleTypeKind:  return 8;
        case LLVMFP128TypeKind:   return 16;
        case LLVMX86_FP80TypeKind:return 10;
        default: return 0;
    }
}

// Get or create the ifo_field_t struct LLVM type.
// Layout: { i8* name, i32 offset, i32 size, i32 align }
inline LLVMTypeRef get_ifo_field_t_llvm_type(ir_context* ctx) {
    const char* NAME = "std__NS_ifo__NS_ifo_field_t";
    auto it = ctx->struct_types.find(NAME);
    if (it != ctx->struct_types.end()) return it->second;
    LLVMContextRef lctx = ctx->llvm_ctx;
    LLVMTypeRef i8pt = LLVMPointerType(LLVMInt8TypeInContext(lctx), 0);
    LLVMTypeRef i32t = LLVMInt32TypeInContext(lctx);
    LLVMTypeRef fields[4] = { i8pt, i32t, i32t, i32t };
    LLVMTypeRef t = LLVMStructCreateNamed(lctx, NAME);
    LLVMStructSetBody(t, fields, 4, 0);
    ctx->struct_types[NAME] = t;
    return t;
}

inline LLVMValueRef visit_get_ifo_t_expr(expr_node* e, ir_context* ctx) {
    if (!e->cast_type) {
        return LLVMConstNull(LLVMPointerType(LLVMInt8TypeInContext(ctx->llvm_ctx), 0));
    }

    LLVMContextRef lctx = ctx->llvm_ctx;
    LLVMTypeRef i32t    = LLVMInt32TypeInContext(lctx);
    LLVMTypeRef i8pt    = LLVMPointerType(LLVMInt8TypeInContext(lctx), 0);
    LLVMTypeRef ifo_t   = get_ifo_t_llvm_type(ctx);
    LLVMTypeRef field_t = get_ifo_field_t_llvm_type(ctx);

    type_node* tn = e->cast_type;
    LLVMTypeRef llvm_t = llvm_type_of(tn, ctx);

    std::string tname = ifo_type_name(tn);
    static int ifo_seq = 0;
    std::string safe_base = ".ifo_" + tname + "_" + std::to_string(ifo_seq++);
    for (char& c : safe_base) if (c == '*') c = 'p';

    // --- determine kind, size, align, bits, is_signed ---
    int kind = 8;
    unsigned sz = 0, al = 0, bits = 0;
    int is_signed_flag = 0;

    if (tn->pointer_depth > 0) {
        kind = 1; sz = 8; al = 8; bits = 64;
    } else if (tn->is_primitive && tn->prim.has_value()) {
        kind = 0;
        LLVMTypeKind tk = LLVMGetTypeKind(llvm_t);
        if (tk == LLVMIntegerTypeKind) {
            bits = LLVMGetIntTypeWidth(llvm_t);
            sz   = (bits + 7) / 8; al = (sz > 8) ? 8 : sz;
            prim_type_t p = tn->prim.value();
            is_signed_flag = (!is_unsigned_prim(p) && p != prim_type_t::arb_bool) ? 1 : 0;
        } else if (tk == LLVMHalfTypeKind)    { bits=16;  sz=2;  al=2;  }
          else if (tk == LLVMFloatTypeKind)    { bits=32;  sz=4;  al=4;  }
          else if (tk == LLVMDoubleTypeKind)   { bits=64;  sz=8;  al=8;  }
          else if (tk == LLVMFP128TypeKind)    { bits=128; sz=16; al=16; }
    } else if (!tn->is_primitive && tn->name.has_value()) {
        if (ctx->union_names.count(*tn->name))      kind = 3;
        else if (ctx->class_infos.count(*tn->name)) kind = 5;
        else                                         kind = 2;
        auto sit = ctx->struct_field_types.find(*tn->name);
        if (sit != ctx->struct_field_types.end()) {
            for (auto ft : sit->second) sz += ifo_llvm_sizeof(ft);
            al = 8;
        }
    }

    // --- build ifo_field_t array for compound types ---
    LLVMValueRef fields_ptr = LLVMConstNull(i8pt);
    unsigned field_count = 0;

    if (!tn->is_primitive && tn->name.has_value()) {
        auto nit = ctx->struct_field_names.find(*tn->name);
        auto tit = ctx->struct_field_types.find(*tn->name);
        if (nit != ctx->struct_field_names.end() && tit != ctx->struct_field_types.end()) {
            const auto& fnames = nit->second;
            const auto& ftypes = tit->second;
            field_count = (unsigned)std::min(fnames.size(), ftypes.size());
            if (field_count > 0) {
                std::vector<LLVMValueRef> field_consts;
                unsigned offset = 0;
                for (unsigned fi = 0; fi < field_count; fi++) {
                    unsigned fsz = ifo_llvm_sizeof(ftypes[fi]);
                    unsigned fal = fsz > 0 ? fsz : 1;
                    if (fal > 1) offset = (offset + fal - 1) & ~(fal - 1); // align
                    LLVMValueRef fname_str = LLVMBuildGlobalStringPtr(
                        ctx->llvm_builder, fnames[fi].c_str(),
                        (safe_base + "_fn" + std::to_string(fi)).c_str());
                    LLVMValueRef fc[4] = {
                        fname_str,
                        LLVMConstInt(i32t, offset, 0),
                        LLVMConstInt(i32t, fsz, 0),
                        LLVMConstInt(i32t, fal, 0),
                    };
                    field_consts.push_back(LLVMConstNamedStruct(field_t, fc, 4));
                    offset += fsz;
                }
                LLVMTypeRef arr_t = LLVMArrayType(field_t, field_count);
                LLVMValueRef arr_init = LLVMConstArray(field_t,
                    field_consts.data(), field_count);
                LLVMValueRef arr_g = LLVMAddGlobal(ctx->llvm_mod, arr_t,
                    (safe_base + "_fields").c_str());
                LLVMSetInitializer(arr_g, arr_init);
                LLVMSetGlobalConstant(arr_g, 1);
                LLVMSetLinkage(arr_g, LLVMPrivateLinkage);
                fields_ptr = LLVMConstBitCast(arr_g, i8pt);
            }
        }
    }

    // --- elem_type for pointer types ---
    LLVMValueRef elem_type_ptr = LLVMConstNull(i8pt);
    if (tn->pointer_depth > 0) {
        // Build ifo_t for the pointee type (one level of pointer removed)
        auto* inner_tn = new type_node(*tn);
        inner_tn->pointer_depth--;
        auto* inner_e = new expr_node();
        inner_e->kind = expr_kind::get_ifo_t_e;
        inner_e->cast_type = inner_tn;
        inner_e->line = e->line;
        LLVMValueRef inner_ifo = visit_get_ifo_t_expr(inner_e, ctx);
        elem_type_ptr = LLVMConstBitCast(inner_ifo, i8pt);
    }

    // --- build ifo_method_t array for istruc types ---
    LLVMValueRef methods_ptr = LLVMConstNull(i8pt);
    unsigned method_count = 0;
    LLVMTypeRef method_t = get_ifo_method_t_llvm_type(ctx);

    if (!tn->is_primitive && tn->name.has_value()) {
        auto cit = ctx->class_infos.find(*tn->name);
        if (cit != ctx->class_infos.end()) {
            const auto& meths = cit->second.methods;
            method_count = (unsigned)meths.size();
            if (method_count > 0) {
                std::vector<LLVMValueRef> meth_consts;
                for (unsigned mi = 0; mi < method_count; mi++) {
                    const auto& m = meths[mi];
                    LLVMValueRef mname_str = LLVMBuildGlobalStringPtr(
                        ctx->llvm_builder, m.name.c_str(),
                        (safe_base + "_mn" + std::to_string(mi)).c_str());
                    unsigned ret_sz = 0;
                    if (m.ret_type) {
                        LLVMTypeRef rt = llvm_type_of(m.ret_type, ctx);
                        ret_sz = ifo_llvm_sizeof(rt);
                    }
                    LLVMValueRef mc[3] = {
                        mname_str,
                        LLVMConstInt(i32t, (unsigned)m.param_count, 0),
                        LLVMConstInt(i32t, ret_sz, 0),
                    };
                    meth_consts.push_back(LLVMConstNamedStruct(method_t, mc, 3));
                }
                LLVMTypeRef marr_t = LLVMArrayType(method_t, method_count);
                LLVMValueRef marr_init = LLVMConstArray(method_t,
                    meth_consts.data(), method_count);
                LLVMValueRef marr_g = LLVMAddGlobal(ctx->llvm_mod, marr_t,
                    (safe_base + "_methods").c_str());
                LLVMSetInitializer(marr_g, marr_init);
                LLVMSetGlobalConstant(marr_g, 1);
                LLVMSetLinkage(marr_g, LLVMPrivateLinkage);
                methods_ptr = LLVMConstBitCast(marr_g, i8pt);
            }
        }
    }

    // --- type name string ---
    LLVMValueRef name_str = LLVMBuildGlobalStringPtr(ctx->llvm_builder, tname.c_str(),
                                                      (safe_base + "_str").c_str());

    LLVMValueRef fvals[11] = {
        name_str,
        LLVMConstInt(i32t, sz,                       0),
        LLVMConstInt(i32t, al,                       0),
        LLVMConstInt(i32t, (unsigned)kind,           0),
        LLVMConstInt(i32t, bits,                     0),
        LLVMConstInt(i32t, (unsigned)is_signed_flag, 0),
        LLVMConstInt(i32t, field_count,              0),
        fields_ptr,      // ifo_field_t*
        elem_type_ptr,   // ifo_t* (null for non-pointer types)
        LLVMConstInt(i32t, method_count,             0),
        methods_ptr,     // ifo_method_t*
    };
    LLVMValueRef ifo_const = LLVMConstNamedStruct(ifo_t, fvals, 11);

    LLVMValueRef g = LLVMAddGlobal(ctx->llvm_mod, ifo_t, safe_base.c_str());
    LLVMSetInitializer(g, ifo_const);
    LLVMSetGlobalConstant(g, 1);
    LLVMSetLinkage(g, LLVMPrivateLinkage);
    return g;
}

// ------------------------------------------------------------------ dispatcher

inline LLVMValueRef visit_expr(expr_node* e, ir_context* ctx) {
    switch (e->kind) {
        case expr_kind::null_lit:
            return LLVMConstNull(LLVMPointerType(LLVMInt8TypeInContext(ctx->llvm_ctx), 0));
        case expr_kind::null_coal:  return visit_null_coal_expr(e, ctx);
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
        case expr_kind::annotation:  return visit_annotation_expr(e, ctx);
        case expr_kind::class_init:  return visit_class_init(e, ctx);
        case expr_kind::error_lit:   return visit_error_lit_expr(e, ctx);
        case expr_kind::try_expr:    return visit_try_expr_func(e, ctx);
        case expr_kind::except_expr: return visit_except_expr_func(e, ctx);
        case expr_kind::get_ifo_t_e: return visit_get_ifo_t_expr(e, ctx);
        case expr_kind::import_expr:    // @import(...) — comptime only; no runtime value
        case expr_kind::sta_type_expr:  // sta used as value — comptime only
            return LLVMConstNull(LLVMPointerType(LLVMInt8TypeInContext(ctx->llvm_ctx), 0));
        default:
            throw std::runtime_error("IR: Unknown expr_kind");
    }
}
