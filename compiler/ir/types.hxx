#pragma once
#include "context.hxx"
#include "../parser/expr.hxx"

// Returns true if the type_node is an unsigned integer primitive (non-pointer).
inline bool is_unsigned_prim(prim_type_t p) {
    return p == prim_type_t::arb_uint || p == prim_type_t::arb_bool;
}

inline bool is_unsigned_type_node(const type_node* t) {
    if (!t || !t->is_primitive || !t->prim.has_value()) return false;
    if (t->pointer_depth > 0) return false;
    return is_unsigned_prim(t->prim.value());
}

// Map a floating-point bit-width to the nearest LLVM float type.
// LLVM supports: half(16), float(32), double(64), x86_fp80(80), fp128(128).
inline LLVMTypeRef llvm_float_for_width(uint32_t bw, LLVMContextRef ctx) {
    if (bw <= 16)  return LLVMHalfTypeInContext(ctx);
    if (bw <= 32)  return LLVMFloatTypeInContext(ctx);
    if (bw <= 64)  return LLVMDoubleTypeInContext(ctx);
    if (bw <= 80)  return LLVMX86FP80TypeInContext(ctx);
    return LLVMFP128TypeInContext(ctx);
}

// Map a primitive type + bit-width to an LLVMTypeRef.
inline LLVMTypeRef llvm_type_of_prim(prim_type_t p, uint32_t bw, LLVMContextRef ctx) {
    switch (p) {
        case prim_type_t::char_t:    return LLVMInt8TypeInContext(ctx);
        case prim_type_t::void_t:    return LLVMVoidTypeInContext(ctx);
        case prim_type_t::arb_int:
        case prim_type_t::arb_uint:
        case prim_type_t::arb_bool:  return LLVMIntTypeInContext(ctx, bw ? bw : 32);
        case prim_type_t::arb_float: return llvm_float_for_width(bw ? bw : 64, ctx);
        default:                     return LLVMInt32TypeInContext(ctx);
    }
}

// Convert a full type_node* (including pointer depth) to an LLVMTypeRef.
// Named types (struct/union/enum) must already be registered in ctx->struct_types.
inline LLVMTypeRef llvm_type_of(const type_node* t, ir_context* ctx) {
    if (!t) return LLVMVoidTypeInContext(ctx->llvm_ctx);

    // Function pointer type: returntype(params)*
    if (t->is_func_ptr && t->fp_ret) {
        LLVMTypeRef ret_t = llvm_type_of(t->fp_ret, ctx);
        std::vector<LLVMTypeRef> param_ts;
        for (auto* pt : t->fp_params)
            param_ts.push_back(llvm_type_of(pt, ctx));
        LLVMTypeRef fn_t = LLVMFunctionType(ret_t,
                                             param_ts.data(),
                                             static_cast<unsigned>(param_ts.size()),
                                             t->fp_variadic ? 1 : 0);
        return LLVMPointerType(fn_t, 0);
    }

    // Self-ref: opaque pointer (i8*)
    if (t->is_self_ref)
        return LLVMPointerType(LLVMInt8TypeInContext(ctx->llvm_ctx), 0);
    // &memstr: fat pointer {ptr, ptr} = {data_ptr, vtable_ptr}
    if (t->is_memstr_ref) {
        if (!ctx->memstr_fat_type) {
            ctx->memstr_fat_type = LLVMStructCreateNamed(ctx->llvm_ctx, "__memstr_fat__");
            LLVMTypeRef ptr_t = LLVMPointerTypeInContext(ctx->llvm_ctx, 0);
            LLVMTypeRef fields[2] = {ptr_t, ptr_t};
            LLVMStructSetBody(ctx->memstr_fat_type, fields, 2, 0);
        }
        return ctx->memstr_fat_type;
    }

    LLVMTypeRef base;
    if (t->is_primitive) {
        base = llvm_type_of_prim(t->prim.value(), t->bit_width, ctx->llvm_ctx);
    } else {
        const std::string& name = t->name.value_or("");
        // Generic type parameter substitution takes precedence.
        auto subit = ctx->type_subst.find(name);
        if (subit != ctx->type_subst.end()) {
            base = subit->second;
        } else {
            // For a generic struct instantiation Name<...>, resolve the monomorphized name.
            std::string lookup = name;
            if (!t->type_args.empty()) {
                // Build mangled name matching generic_class_mangled (defined below).
                std::string mangled = name + "__G";
                for (auto* ta : t->type_args) {
                    mangled += "_";
                    if (!ta) { mangled += "v"; continue; }
                    if (ta->is_primitive && ta->prim) {
                        switch (ta->prim.value()) {
                            case prim_type_t::char_t:    mangled += "c"; break;
                            case prim_type_t::arb_int:   mangled += "i" + std::to_string(ta->bit_width); break;
                            case prim_type_t::arb_uint:  mangled += "u" + std::to_string(ta->bit_width); break;
                            case prim_type_t::arb_float: mangled += "f" + std::to_string(ta->bit_width); break;
                            case prim_type_t::arb_bool:  mangled += "b" + std::to_string(ta->bit_width); break;
                            case prim_type_t::void_t:    mangled += "v"; break;
                            default:                     mangled += "x"; break;
                        }
                    } else if (ta->name) { mangled += *ta->name; }
                    else                 { mangled += "x"; }
                }
                if (ctx->struct_types.count(mangled)) lookup = mangled;
            }
            auto it = ctx->struct_types.find(lookup);
            if (it != ctx->struct_types.end()) {
                base = it->second;
            } else {
                // Check scalar/pointer typedef aliases (e.g. typedef f64 Real).
                auto ta_it = ctx->typedef_aliases.find(lookup);
                if (ta_it != ctx->typedef_aliases.end())
                    return llvm_type_of(ta_it->second, ctx);
                // Try namespace-qualified name for intra-namespace type references.
                bool ns_found = false;
                if (!ctx->current_namespace.empty()) {
                    std::string ns_name = ctx->current_namespace + "__NS_" + lookup;
                    auto ns_it = ctx->struct_types.find(ns_name);
                    if (ns_it != ctx->struct_types.end()) {
                        base = ns_it->second;
                        ns_found = true;
                    }
                }
                if (!ns_found) {
                    // Fallback: opaque i8* for unknown types (avoids hard crash)
                    base = LLVMInt8TypeInContext(ctx->llvm_ctx);
                }
            }
        }
    }

    // Apply pointer depth first, then wrap in array if needed.
    for (int i = 0; i < t->pointer_depth; i++)
        base = LLVMPointerType(base, 0);

    if (t->array_size.has_value()) {
        uint64_t n = 0;
        if (auto* sz = t->array_size.value()) {
            if (sz->kind == expr_kind::int_lit) {
                n = static_cast<uint64_t>(sz->int_val);
            } else if (sz->kind == expr_kind::identifier) {
                // Try namespace-qualified lookup first, then bare name.
                auto try_ns = [&](const std::string& k) -> bool {
                    auto it = ctx->constexpr_int_vals.find(k);
                    if (it != ctx->constexpr_int_vals.end()) { n = static_cast<uint64_t>(it->second); return true; }
                    return false;
                };
                if (!ctx->current_namespace.empty())
                    try_ns(ctx->current_namespace + "__NS_" + sz->str_val);
                if (!n) try_ns(sz->str_val);
            }
        }
        return LLVMArrayType(base, static_cast<unsigned>(n));
    }

    return base;
}

// Returns true when an LLVM type is a floating-point kind.
inline bool llvm_is_float(LLVMTypeRef t) {
    LLVMTypeKind k = LLVMGetTypeKind(t);
    return k == LLVMHalfTypeKind   || k == LLVMBFloatTypeKind  ||
           k == LLVMFloatTypeKind  || k == LLVMDoubleTypeKind  ||
           k == LLVMX86_FP80TypeKind || k == LLVMFP128TypeKind ||
           k == LLVMPPC_FP128TypeKind;
}

// Returns the byte size of an LLVM type (used for ADT payload layout).
inline unsigned adt_type_byte_size(LLVMTypeRef t, ir_context* /*ctx*/) {
    if (!t) return 0;
    LLVMTypeKind k = LLVMGetTypeKind(t);
    if (k == LLVMIntegerTypeKind)   return (LLVMGetIntTypeWidth(t) + 7) / 8;
    if (k == LLVMHalfTypeKind)      return 2;
    if (k == LLVMBFloatTypeKind)    return 2;
    if (k == LLVMFloatTypeKind)     return 4;
    if (k == LLVMDoubleTypeKind)    return 8;
    if (k == LLVMX86_FP80TypeKind)  return 10;
    if (k == LLVMFP128TypeKind)     return 16;
    if (k == LLVMPointerTypeKind)   return 8;
    if (k == LLVMArrayTypeKind) {
        unsigned n  = LLVMGetArrayLength(t);
        LLVMTypeRef et = LLVMGetElementType(t);
        return n * adt_type_byte_size(et, nullptr);
    }
    if (k == LLVMStructTypeKind) {
        unsigned total = 0;
        unsigned nf = LLVMCountStructElementTypes(t);
        for (unsigned i = 0; i < nf; ++i) {
            LLVMTypeRef ft = LLVMStructGetTypeAtIndex(t, i);
            total += adt_type_byte_size(ft, nullptr);
        }
        return total;
    }
    return 0;
}

// Resolve a type_node through typedef aliases in the IR context.
inline type_node ir_resolve_alias_node(const type_node* t, ir_context* ctx) {
    if (!t) return {};
    if (t->is_primitive || t->pointer_depth > 0 || !t->name) return *t;
    auto it = ctx->typedef_aliases.find(*t->name);
    if (it == ctx->typedef_aliases.end()) return *t;
    // Recursively resolve
    return ir_resolve_alias_node(it->second, ctx);
}

// Mangle a generic function name with concrete LLVM type args.
inline std::string generic_func_mangled(const std::string& name,
                                         const std::vector<LLVMTypeRef>& targs) {
    std::string s = name + "__G";
    for (auto t : targs) {
        s += "_";
        if (!t) { s += "v"; continue; }
        LLVMTypeKind k = LLVMGetTypeKind(t);
        if (k == LLVMIntegerTypeKind)  { s += "i" + std::to_string(LLVMGetIntTypeWidth(t)); }
        else if (k == LLVMFloatTypeKind)  s += "f32";
        else if (k == LLVMDoubleTypeKind) s += "f64";
        else if (k == LLVMHalfTypeKind)   s += "f16";
        else if (k == LLVMPointerTypeKind) s += "p";
        else                               s += "x";
    }
    return s;
}

// Mangle a generic class name with concrete AST type args.
inline std::string generic_class_mangled(const std::string& name,
                                          const std::vector<type_node*>& targs) {
    std::string s = name + "__G";
    for (auto* t : targs) {
        s += "_";
        if (!t) { s += "v"; continue; }
        if (t->is_primitive && t->prim) {
            switch (t->prim.value()) {
                case prim_type_t::char_t:    s += "c";   break;
                case prim_type_t::arb_int:   s += "i" + std::to_string(t->bit_width); break;
                case prim_type_t::arb_uint:  s += "u" + std::to_string(t->bit_width); break;
                case prim_type_t::arb_float: s += "f" + std::to_string(t->bit_width); break;
                case prim_type_t::arb_bool:  s += "b" + std::to_string(t->bit_width); break;
                case prim_type_t::void_t:    s += "v";   break;
                default:                     s += "x";   break;
            }
        } else if (t->name) {
            s += *t->name;
        } else {
            s += "x";
        }
    }
    return s;
}
