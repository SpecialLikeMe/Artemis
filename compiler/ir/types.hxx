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
    LLVMTypeRef base;

    if (t->is_primitive) {
        base = llvm_type_of_prim(t->prim.value(), ctx->llvm_ctx);
    } else {
        const std::string& name = t->name.value_or("");
        auto it = ctx->struct_types.find(name);
        if (it != ctx->struct_types.end()) {
            base = it->second;
        } else {
            // Enum values are represented as i32.
            base = LLVMInt32TypeInContext(ctx->llvm_ctx);
        }
    }

    // Apply array size before pointer decorators.
    LLVMTypeRef result = base;
    if (t->array_size.has_value() && t->pointer_depth == 0) {
        auto* sz = t->array_size.value();
        if (sz->kind == expr_kind::int_lit) {
            unsigned n = static_cast<unsigned>(sz->int_val);
            result = LLVMArrayType(result, n);
        }
    }

    // Apply pointer decorators.
    for (int i = 0; i < t->pointer_depth; i++)
        result = LLVMPointerType(result, 0 /* address space 0 */);

    return result;
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
