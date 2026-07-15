// Type lowering: AST type_node -> LLVMTypeRef for the Artemis self-hosting compiler.

namespace ir {

// Compute byte size of an LLVM type without requiring data layout.
u64 llvm_type_byte_size(i8* ty) {
    if (ty == (i8*)0) { return 8; }
    i32 k = LLVMGetTypeKind(ty);
    if (k == LLVMIntegerTypeKind) {
        u32 bits = LLVMGetIntTypeWidth(ty);
        return (u64)((bits + 7) / 8);
    }
    if (k == LLVMFloatTypeKind)  { return 4; }
    if (k == LLVMDoubleTypeKind) { return 8; }
    if (k == LLVMX86_FP80TypeKind) { return 10; }
    if (k == LLVMPointerTypeKind) { return 8; }
    if (k == LLVMArrayTypeKind) {
        i8* elem_t = LLVMGetElementType(ty);
        u64 elem_sz = llvm_type_byte_size(elem_t);
        u32 cnt = LLVMGetArrayLength(ty);
        return elem_sz * (u64)cnt;
    }
    if (k == LLVMStructTypeKind) {
        // Sum field sizes (conservative: no padding)
        u32 nf = LLVMCountStructElementTypes(ty);
        u64 total = 0;
        u32 fi = 0;
        while (fi < nf) {
            i8* ft = LLVMStructGetTypeAtIndex(ty, fi);
            total = total + llvm_type_byte_size(ft);
            fi = fi + 1;
        }
        return total;
    }
    return 8;
}

// Returns true if the type_node is an unsigned integer primitive.
bool is_unsigned_type_node(parser.type_node* t) {
    if (t == (parser.type_node*)0) { return false; }
    if (!t.is_primitive) { return false; }
    if (t.pointer_depth > 0) { return false; }
    if (!t.has_prim) { return false; }
    return t.prim == arb_uint || t.prim == arb_bool || t.prim == arb_nat;
}

// Map a floating-point bit-width to the nearest LLVM float type.
i8* llvm_float_for_width(u32 bw, i8* llvm_ctx) {
    if (bw <= 16) { return LLVMHalfTypeInContext(llvm_ctx); }
    if (bw <= 32) { return LLVMFloatTypeInContext(llvm_ctx); }
    if (bw <= 64) { return LLVMDoubleTypeInContext(llvm_ctx); }
    if (bw <= 80) { return LLVMX86FP80TypeInContext(llvm_ctx); }
    return LLVMFP128TypeInContext(llvm_ctx);
}

// Return or create the LLVM named struct type for a rational number of given bit-width.
// Layout: { iN numerator, iN denominator }
// Named so that LLVMGetStructName() returns "__rational_N" for field lookup.
i8* rational_llvm_type(u32 bw, i8* llvm_ctx) {
    u32 w = (bw == 0) ? (u32)64 : bw;
    i8 name[64];
    snprintf(name, (u64)64, "__rational_%d", (i32)w);
    i8* existing = LLVMGetTypeByName2(llvm_ctx, name);
    if (existing != (i8*)0) { return existing; }
    i8* st = LLVMStructCreateNamed(llvm_ctx, name);
    i8* it = LLVMIntTypeInContext(llvm_ctx, (i32)w);
    i8* flds[2]; flds[0] = it; flds[1] = it;
    LLVMStructSetBody(st, flds, (u32)2, 0);
    return st;
}

// Return the LLVM named struct type for a complex number of given bit-width.
// Layout: { fN real, fN imag }
// Named so that LLVMGetStructName() returns "__complex_N" for field lookup.
i8* complex_llvm_type(u32 bw, i8* llvm_ctx) {
    u32 w = (bw == 0) ? (u32)64 : bw;
    i8 name[64];
    snprintf(name, (u64)64, "__complex_%d", (i32)w);
    i8* existing = LLVMGetTypeByName2(llvm_ctx, name);
    if (existing != (i8*)0) { return existing; }
    i8* st = LLVMStructCreateNamed(llvm_ctx, name);
    i8* ft = llvm_float_for_width(w, llvm_ctx);
    i8* flds[2]; flds[0] = ft; flds[1] = ft;
    LLVMStructSetBody(st, flds, (u32)2, 0);
    return st;
}

// Map a primitive type + bit-width to an LLVMTypeRef.
i8* llvm_type_of_prim(i32 prim, u32 bw, i8* llvm_ctx) {
    if (prim == char_t)       { return LLVMInt8TypeInContext(llvm_ctx); }
    if (prim == void_t)       { return LLVMVoidTypeInContext(llvm_ctx); }
    if (prim == arb_float)    { return llvm_float_for_width(bw == 0 ? (u32)64 : bw, llvm_ctx); }
    if (prim == arb_rational) { return rational_llvm_type(bw, llvm_ctx); }
    if (prim == arb_complex)  { return complex_llvm_type(bw, llvm_ctx); }
    // arb_char_w: N-bit unsigned char
    if (prim == arb_char_w) {
        u32 w = (bw == 0) ? (u32)8 : bw;
        return LLVMIntTypeInContext(llvm_ctx, (i32)w);
    }
    // arb_str_w: pointer to N-bit char (pointer type)
    if (prim == arb_str_w) {
        return LLVMPointerTypeInContext(llvm_ctx, 0);
    }
    // arb_nat: natural number ≥0 — unsigned integer of width N
    if (prim == arb_nat) {
        u32 w = (bw == 0) ? (u32)32 : bw;
        return LLVMIntTypeInContext(llvm_ctx, (i32)w);
    }
    // arb_zint: integer ring ℤ — signed integer of width N (distinct from arb_int)
    if (prim == arb_zint) {
        u32 w = (bw == 0) ? (u32)32 : bw;
        return LLVMIntTypeInContext(llvm_ctx, (i32)w);
    }
    // arb_real: real number ℝ — float of width N (distinct from arb_float)
    if (prim == arb_real) {
        return llvm_float_for_width(bw == 0 ? (u32)64 : bw, llvm_ctx);
    }
    // arb_alg: algebraic number — always f64 at runtime (subset of ℝ, algebraic)
    if (prim == arb_alg) {
        return LLVMDoubleTypeInContext(llvm_ctx);
    }
    // arb_int, arb_uint, arb_bool: integer type
    u32 width = bw == 0 ? (u32)32 : bw;
    return LLVMIntTypeInContext(llvm_ctx, (i32)width);
}

// Forward declarations (defined later in decls.arc / types.arc below).
i8* resolve_typedef_alias(parser.type_node* t, ir_context* ctx);
// Generic class monomorphization — defined in decls.arc (included after types.arc).
i8* ir_get_or_monomorphize_generic_class(parser.type_node* t, ir_context* ctx);
// memstr fat-pointer type creation — defined in decls.arc.
void ensure_memstr_types(ir_context* ctx);

// Convert a full type_node* (including pointer depth) to an LLVMTypeRef.
i8* llvm_type_of(parser.type_node* t, ir_context* ctx) {
    if (t == (parser.type_node*)0) {
        return LLVMVoidTypeInContext(ctx.llvm_ctx);
    }

    // interface NAME — fat pointer (for now emitted as void*)
    if (t.is_interface) {
        return LLVMPointerType(LLVMInt8TypeInContext(ctx.llvm_ctx), 0);
    }

    // Function pointer: returntype(params)*
    if (t.is_func_ptr && t.fp_ret != (i8*)0) {
        i8* ret_t = llvm_type_of((parser.type_node*)t.fp_ret, ctx);

        // Build parameter type array
        i32 nparams = t.fp_params_len;
        i8** param_ts = (i8**)0;
        if (nparams > 0) {
            param_ts = (i8**)arc_malloc(sizeof(i8*) * (u64)nparams);
            i32 pi = 0;
            while (pi < nparams) {
                parser.type_node* pt = (parser.type_node*)t.fp_params[pi];
                param_ts[pi] = llvm_type_of(pt, ctx);
                pi = pi + 1;
            }
        }
        i32 variadic = t.fp_variadic ? 1 : 0;
        i8* fn_t = LLVMFunctionType(ret_t, param_ts, nparams, variadic);
        if (param_ts != (i8**)0) { arc_free((i8*)param_ts); }
        return LLVMPointerType(fn_t, 0);
    }

    i8* base = (i8*)0;
    if (t.is_primitive && t.has_prim) {
        base = llvm_type_of_prim(t.prim, (u32)t.bit_width, ctx.llvm_ctx);
        // Register struct meta for complex and rational types so field access (.re/.im, .num/.den) works.
        if ((t.prim == arb_complex || t.prim == arb_rational) && base != (i8*)0) {
            u32 bw = (t.bit_width == 0) ? (u32)64 : (u32)t.bit_width;
            i8 sname[64];
            if (t.prim == arb_complex)  { snprintf(sname, (u64)64, "__complex_%d",  (i32)bw); }
            else                         { snprintf(sname, (u64)64, "__rational_%d", (i32)bw); }
            // Register in struct_types if not already there
            if (st_map_get(&ctx.struct_types, sname) == (i8*)0) {
                st_map_set(&ctx.struct_types, lexer.str_dup(sname), base);
                struct_meta sm;
                sm.name = lexer.str_dup(sname);
                name_list_init(&sm.field_names);
                type_list_init(&sm.field_types);
                bool_list_init(&sm.field_unsigned);
                type_list_init(&sm.field_pointee);
                sm.is_union  = false;
                sm.is_istruc = false;
                i8* elem_t = LLVMStructGetTypeAtIndex(base, (u32)0);
                if (t.prim == arb_complex) {
                    name_list_push(&sm.field_names, lexer.str_dup("re"));
                    type_list_push(&sm.field_types, elem_t);
                    bool_list_push(&sm.field_unsigned, false);
                    type_list_push(&sm.field_pointee, (i8*)0);
                    name_list_push(&sm.field_names, lexer.str_dup("im"));
                    type_list_push(&sm.field_types, elem_t);
                    bool_list_push(&sm.field_unsigned, false);
                    type_list_push(&sm.field_pointee, (i8*)0);
                } else {
                    name_list_push(&sm.field_names, lexer.str_dup("num"));
                    type_list_push(&sm.field_types, elem_t);
                    bool_list_push(&sm.field_unsigned, false);
                    type_list_push(&sm.field_pointee, (i8*)0);
                    name_list_push(&sm.field_names, lexer.str_dup("den"));
                    type_list_push(&sm.field_types, elem_t);
                    bool_list_push(&sm.field_unsigned, false);
                    type_list_push(&sm.field_pointee, (i8*)0);
                }
                struct_meta_vec_push(&ctx.struct_meta_tbl, sm);
            }
        }
    } else {
        i8* name = t.name;
        if (name == (i8*)0) {
            return LLVMVoidTypeInContext(ctx.llvm_ctx);
        }

        // &memstr fat pointer: return the fat struct type (by value)
        if (t.is_memstr_ref) {
            ensure_memstr_types(ctx);
            // Fat pointer is passed by value — return the struct type itself (no extra ptr wrap)
            return ctx.memstr_fat_type;
        }

        // Generic instantiation: if type has type args, monomorphize first
        if (t.type_args_len > 0 && base == (i8*)0) {
            base = ir_get_or_monomorphize_generic_class(t, ctx);
        }

        // Check struct types
        i8* found_struct = (i8*)0;
        if (base == (i8*)0) { found_struct = st_map_get(&ctx.struct_types, name); }
        if (found_struct != (i8*)0) {
            base = found_struct;
        } else if (base == (i8*)0) {
            // Check typedef aliases
            i8* alias_tn = typedef_map_get(&ctx.typedef_aliases, name);
            if (alias_tn != (i8*)0) {
                parser.type_node* resolved_tn = (parser.type_node*)alias_tn;
                i8* resolved = llvm_type_of(resolved_tn, ctx);
                // Apply pointer depth on top of resolved
                i32 pi = 0;
                while (pi < t.pointer_depth) {
                    resolved = LLVMPointerType(resolved, 0);
                    pi = pi + 1;
                }
                return resolved;
            }
            // Try namespace-qualified lookup
            if (ctx.current_namespace != (i8*)0) {
                i8 ns_name[512];
                snprintf(ns_name, (u64)512, "%s__NS_%s", ctx.current_namespace, name);
                found_struct = st_map_get(&ctx.struct_types, ns_name);
                if (found_struct != (i8*)0) {
                    base = found_struct;
                }
            }
            if (base == (i8*)0) {
                // Check type parameter bindings (for generic instantiation)
                i8* tp_t = st_map_get(&ctx.type_param_bindings, name);
                if (tp_t != (i8*)0) {
                    base = tp_t;
                } else {
                    // Fallback to i8* (opaque pointer)
                    base = LLVMInt8TypeInContext(ctx.llvm_ctx);
                }
            }
        }
    }

    // Apply pointer depth
    i32 pi = 0;
    while (pi < t.pointer_depth) {
        base = LLVMPointerType(base, 0);
        pi = pi + 1;
    }

    // Array type
    if (t.array_size_ptr != (i8*)0) {
        parser.expr_node* sz_expr = (parser.expr_node*)t.array_size_ptr;
        u64 n = 0;
        if (sz_expr.kind == ek_int_lit) {
            n = (u64)sz_expr.int_val;
        } else if (sz_expr.kind == ek_identifier && sz_expr.str_val != (i8*)0) {
            // Try to look up constexpr value
            i8* cv = sv_map_get(&ctx.constexpr_int_vals_map, sz_expr.str_val);
            if (cv != (i8*)0) {
                n = (u64)(i64)cv;
            }
        }
        return LLVMArrayType(base, (i32)n);
    }

    return base;
}

// Returns the bare LLVMFunctionType for a func-ptr type node (no pointer wrapper).
// Used to store the function type for indirect-call resolution in opaque-pointer mode.
i8* llvm_func_type_of(parser.type_node* t, ir_context* ctx) {
    if (t == (parser.type_node*)0) { return (i8*)0; }
    if (!t.is_func_ptr || t.fp_ret == (i8*)0) { return (i8*)0; }
    i8* ret_t = llvm_type_of((parser.type_node*)t.fp_ret, ctx);
    i32 nparams = t.fp_params_len;
    i8** param_ts = (i8**)0;
    if (nparams > 0) {
        param_ts = (i8**)arc_malloc(sizeof(i8*) * (u64)nparams);
        i32 pi = 0;
        while (pi < nparams) {
            parser.type_node* pt = (parser.type_node*)t.fp_params[pi];
            param_ts[pi] = llvm_type_of(pt, ctx);
            pi = pi + 1;
        }
    }
    i32 variadic = t.fp_variadic ? 1 : 0;
    i8* fn_t = LLVMFunctionType(ret_t, param_ts, nparams, variadic);
    if (param_ts != (i8**)0) { arc_free((i8*)param_ts); }
    return fn_t;
}

// Resolve typedef alias: returns the underlying type_node.
parser.type_node* resolve_typedef_alias_node(parser.type_node* t, ir_context* ctx) {
    if (t == (parser.type_node*)0) { return (parser.type_node*)0; }
    if (t.is_primitive) { return t; }
    if (t.pointer_depth > 0) { return t; }
    if (t.name == (i8*)0) { return t; }
    i8* alias_tn = typedef_map_get(&ctx.typedef_aliases, t.name);
    if (alias_tn == (i8*)0) { return t; }
    return resolve_typedef_alias_node((parser.type_node*)alias_tn, ctx);
}

// Returns true when an LLVM type is a floating-point kind.
bool llvm_is_float(i8* t) {
    i32 k = LLVMGetTypeKind(t);
    return k == LLVMHalfTypeKind   || k == LLVMBFloatTypeKind  ||
           k == LLVMFloatTypeKind  || k == LLVMDoubleTypeKind  ||
           k == LLVMX86_FP80TypeKind || k == LLVMFP128TypeKind;
}

} // namespace ir
