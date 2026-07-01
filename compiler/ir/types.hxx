#pragma once
#include "context.hxx"
#include "../parser/expr.hxx"

// Map a primitive type to its LLVM type.
// Notes on non-standard widths:
//   f8  -> i8  (no native 8-bit float in portable LLVM C API)
//   f256/f512 -> fp128 (nearest available IEEE float)
//   b*  -> iN  (bool variants are plain integer types of matching width)
inline LLVMTypeRef llvm_type_of_prim(prim_type_t p, LLVMContextRef ctx) {
    switch (p) {
        case prim_type_t::char_t:
        case prim_type_t::i8:
        case prim_type_t::u8:
        case prim_type_t::b8:
        case prim_type_t::f8:    return LLVMInt8TypeInContext(ctx);

        case prim_type_t::i16:
        case prim_type_t::u16:
        case prim_type_t::b16:   return LLVMInt16TypeInContext(ctx);
        case prim_type_t::f16:   return LLVMHalfTypeInContext(ctx);

        case prim_type_t::i32:
        case prim_type_t::u32:
        case prim_type_t::b32:   return LLVMInt32TypeInContext(ctx);
        case prim_type_t::f32:   return LLVMFloatTypeInContext(ctx);

        case prim_type_t::i64:
        case prim_type_t::u64:
        case prim_type_t::b64:   return LLVMInt64TypeInContext(ctx);
        case prim_type_t::f64:   return LLVMDoubleTypeInContext(ctx);

        case prim_type_t::i128:
        case prim_type_t::u128:
        case prim_type_t::b128:  return LLVMInt128TypeInContext(ctx);
        case prim_type_t::f128:  return LLVMFP128TypeInContext(ctx);

        case prim_type_t::i256:
        case prim_type_t::u256:
        case prim_type_t::b256:  return LLVMIntTypeInContext(ctx, 256);
        case prim_type_t::f256:  return LLVMFP128TypeInContext(ctx); // nearest

        case prim_type_t::i512:
        case prim_type_t::u512:
        case prim_type_t::b512:  return LLVMIntTypeInContext(ctx, 512);
        case prim_type_t::f512:  return LLVMFP128TypeInContext(ctx); // nearest

        case prim_type_t::boolean: return LLVMInt1TypeInContext(ctx);
        case prim_type_t::b1:      return LLVMInt1TypeInContext(ctx);

        case prim_type_t::void_t:  return LLVMVoidTypeInContext(ctx);

        default: return LLVMInt32TypeInContext(ctx); // unreachable in valid code
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

    // Self-ref / memstr-ref: return opaque pointer (i8*)
    if (t->is_self_ref || t->is_memstr_ref)
        return LLVMPointerType(LLVMInt8TypeInContext(ctx->llvm_ctx), 0);

    LLVMTypeRef base;
    if (t->is_primitive) {
        base = llvm_type_of_prim(t->prim.value(), ctx->llvm_ctx);
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
                std::string mangled = name + "__G";
                for (auto* ta : t->type_args) {
                    mangled += "_";
                    if (ta->is_primitive)      mangled += std::to_string(static_cast<int>(ta->prim.value_or(prim_type_t::void_t)));
                    else if (ta->name)         mangled += *ta->name;
                    else                       mangled += "x";
                }
                if (ctx->struct_types.count(mangled)) lookup = mangled;
            }
            auto it = ctx->struct_types.find(lookup);
            if (it != ctx->struct_types.end()) {
                base = it->second;
            } else {
                auto al = ctx->typedef_aliases.find(name);
                if (al != ctx->typedef_aliases.end() && al->second) {
                    // Scalar/pointer typedef: the underlying node already carries its own
                    // pointer depth / array; this node's decorators are applied below.
                    base = llvm_type_of(al->second, ctx);
                } else {
                    // Enum values are represented as i32.
                    base = LLVMInt32TypeInContext(ctx->llvm_ctx);
                }
            }
        }
    }

    // Apply pointer decorators first, then wrap in array if needed.
    // This allows T*[N] to correctly produce [N x ptr] rather than ptr.
    LLVMTypeRef result = base;
    for (int i = 0; i < t->pointer_depth; i++)
        result = LLVMPointerType(result, 0 /* address space 0 */);

    if (t->array_size.has_value()) {
        auto* sz = t->array_size.value();
        if (sz->kind == expr_kind::int_lit) {
            unsigned n = static_cast<unsigned>(sz->int_val);
            result = LLVMArrayType(result, n);
        }
    }

    return result;
}

// Resolve typedef aliases on a type_node, combining pointer depths. Returns a
// by-value node whose name/prim reflect the concrete underlying type. Struct
// typedefs (registered in struct_types) are left untouched.
inline type_node ir_resolve_alias_node(const type_node* t, ir_context* ctx) {
    type_node result = *t;
    int guard = 0;
    while (!result.is_primitive && !result.is_func_ptr && result.name.has_value()) {
        auto it = ctx->typedef_aliases.find(result.name.value());
        if (it == ctx->typedef_aliases.end() || !it->second) break;
        int extra_depth = result.pointer_depth;
        result = *it->second;
        result.pointer_depth += extra_depth;
        if (++guard > 64) break;
    }
    return result;
}

// Produce a short identifier-safe string for an LLVM type (for generic name mangling).
inline std::string llvm_type_to_mangle(LLVMTypeRef t) {
    if (!t) return "x";
    LLVMTypeKind k = LLVMGetTypeKind(t);
    if (k == LLVMIntegerTypeKind)
        return "i" + std::to_string(LLVMGetIntTypeWidth(t));
    if (k == LLVMFloatTypeKind)   return "f32";
    if (k == LLVMDoubleTypeKind)  return "f64";
    if (k == LLVMHalfTypeKind)    return "f16";
    if (k == LLVMPointerTypeKind) return "ptr";
    if (k == LLVMVoidTypeKind)    return "void";
    if (k == LLVMStructTypeKind) {
        const char* sn = LLVMGetStructName(t);
        return sn ? std::string(sn) : "struct";
    }
    char* s = LLVMPrintTypeToString(t);
    std::string r(s);
    LLVMDisposeMessage(s);
    for (auto& c : r) if (!std::isalnum(static_cast<unsigned char>(c))) c = '_';
    return r;
}

// Mangle a generic function name with concrete LLVM type args: name__G_i32_f64...
inline std::string generic_func_mangled(const std::string& name, const std::vector<LLVMTypeRef>& targs) {
    std::string mangled = name + "__G";
    for (LLVMTypeRef t : targs) { mangled += "_"; mangled += llvm_type_to_mangle(t); }
    return mangled;
}

// Mangle a generic class/struct name with AST type args: name__G_i32_MyStruct...
inline std::string generic_class_mangled(const std::string& name, const std::vector<type_node*>& args) {
    std::string mangled = name + "__G";
    for (auto* ta : args) {
        mangled += "_";
        if (ta->is_primitive && ta->prim)
            mangled += std::to_string(static_cast<int>(ta->prim.value()));
        else if (ta->name)
            mangled += *ta->name;
        else
            mangled += "x";
    }
    return mangled;
}

// True if the LLVMTypeRef is any floating-point kind.
inline bool llvm_is_float(LLVMTypeRef t) {
    LLVMTypeKind k = LLVMGetTypeKind(t);
    return k == LLVMHalfTypeKind  || k == LLVMFloatTypeKind   ||
           k == LLVMDoubleTypeKind || k == LLVMFP128TypeKind   ||
           k == LLVMX86_FP80TypeKind || k == LLVMBFloatTypeKind;
}

// True if the prim_type_t is an unsigned integer.
inline bool prim_is_unsigned(prim_type_t p) {
    switch (p) {
        case prim_type_t::u8:  case prim_type_t::u16: case prim_type_t::u32:
        case prim_type_t::u64: case prim_type_t::u128: case prim_type_t::u256:
        case prim_type_t::u512: return true;
        default: return false;
    }
}
