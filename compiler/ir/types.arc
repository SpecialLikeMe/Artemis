// Type lowering: AST type_node -> LLVMTypeRef for the Artemis self-hosting compiler.

namespace ir {

// Return the ABI alignment of an LLVM type (approximate, for x86-64 SysV ABI).
fn llvm_type_abi_align(ty: *i8) u64 {
    if (ty == (i8*)0) { return 1; }
    let mut k: i32= LLVMGetTypeKind(ty);
    if (k == LLVMVoidTypeKind)     { return 1; }
    if (k == LLVMHalfTypeKind)     { return 2; }
    if (k == LLVMIntegerTypeKind) {
        let mut bits: u32= LLVMGetIntTypeWidth(ty);
        if (bits <= 8)  { return 1; }
        if (bits <= 16) { return 2; }
        if (bits <= 32) { return 4; }
        return 8;
    }
    if (k == LLVMFloatTypeKind)    { return 4; }
    if (k == LLVMDoubleTypeKind)   { return 8; }
    if (k == LLVMX86_FP80TypeKind) { return 16; }
    if (k == LLVMPointerTypeKind)  { return 8; }
    if (k == LLVMFunctionTypeKind) { return 8; }
    if (k == LLVMArrayTypeKind) {
        let mut elem_t: *i8= LLVMGetElementType(ty);
        return llvm_type_abi_align(elem_t);
    }
    if (k == LLVMStructTypeKind) {
        // Struct align = max alignment of any field
        let mut nf: u32= LLVMCountStructElementTypes(ty);
        let mut max_align: u64= 1;
        let mut fi: u32= 0;
        while (fi < nf) {
            let mut ft: *i8= LLVMStructGetTypeAtIndex(ty, fi);
            let mut fa: u64= llvm_type_abi_align(ft);
            if (fa > max_align) { max_align = fa; }
            fi = fi + 1;
        }
        return max_align;
    }
    return 8;
}

// Compute ABI byte size of an LLVM type (including struct padding) for x86-64 SysV.
fn llvm_type_byte_size(ty: *i8) u64 {
    if (ty == (i8*)0) { return 0; }
    let mut k: i32= LLVMGetTypeKind(ty);
    if (k == LLVMVoidTypeKind)     { return 0; }
    if (k == LLVMHalfTypeKind)     { return 2; }
    if (k == LLVMIntegerTypeKind) {
        let mut bits: u32= LLVMGetIntTypeWidth(ty);
        return (u64)((bits + 7) / 8);
    }
    if (k == LLVMFloatTypeKind)    { return 4; }
    if (k == LLVMDoubleTypeKind)   { return 8; }
    if (k == LLVMX86_FP80TypeKind) { return 16; }
    if (k == LLVMPointerTypeKind)  { return 8; }
    if (k == LLVMFunctionTypeKind) { return 8; }
    if (k == LLVMArrayTypeKind) {
        let mut elem_t: *i8= LLVMGetElementType(ty);
        let mut elem_sz: u64= llvm_type_byte_size(elem_t);
        let mut cnt: u32= LLVMGetArrayLength(ty);
        return elem_sz * (u64)cnt;
    }
    if (k == LLVMStructTypeKind) {
        // Compute size with alignment padding (x86-64 SysV ABI rules)
        let mut nf: u32= LLVMCountStructElementTypes(ty);
        let mut offset: u64= 0;
        let mut struct_align: u64= 1;
        let mut fi: u32= 0;
        while (fi < nf) {
            let mut ft: *i8= LLVMStructGetTypeAtIndex(ty, fi);
            let mut fa: u64= llvm_type_abi_align(ft);
            let mut fs: u64= llvm_type_byte_size(ft);
            // Align offset up to field alignment
            let mut rem: u64= offset % fa;
            if (rem != 0) { offset = offset + (fa - rem); }
            offset = offset + fs;
            if (fa > struct_align) { struct_align = fa; }
            fi = fi + 1;
        }
        // Round up struct size to struct alignment (tail padding)
        let mut tail_rem: u64= offset % struct_align;
        if (tail_rem != 0) { offset = offset + (struct_align - tail_rem); }
        return offset;
    }
    return 8;
}

// Returns true if the type_node is an unsigned integer primitive.
fn is_unsigned_type_node(t: *parser.type_node) bool {
    if (t == (parser.type_node*)0) { return false; }
    if (!t.is_primitive) { return false; }
    if (t.pointer_depth > 0) { return false; }
    if (!t.has_prim) { return false; }
    return t.prim == arb_uint || t.prim == arb_bool || t.prim == arb_nat || t.prim == arb_usize;
}

// Map a floating-point bit-width to the nearest LLVM float type.
fn llvm_float_for_width(bw: u32, llvm_ctx: *i8) *i8 {
    if (bw <= 16) { return LLVMHalfTypeInContext(llvm_ctx); }
    if (bw <= 32) { return LLVMFloatTypeInContext(llvm_ctx); }
    if (bw <= 64) { return LLVMDoubleTypeInContext(llvm_ctx); }
    if (bw <= 80) { return LLVMX86FP80TypeInContext(llvm_ctx); }
    return LLVMFP128TypeInContext(llvm_ctx);
}

// Return or create the LLVM named struct type for a rational number of given bit-width.
// Layout: { iN numerator, iN denominator }
// Named so that LLVMGetStructName() returns "__rational_N" for field lookup.
fn rational_llvm_type(bw: u32, llvm_ctx: *i8) *i8 {
    let mut w: u32= (bw == 0) ? (u32)64 : bw;
    let mut name: [64]i8;
    snprintf(name, (u64)64, "__rational_%d", (i32)w);
    let mut existing: *i8= LLVMGetTypeByName2(llvm_ctx, name);
    if (existing != (i8*)0) { return existing; }
    let mut st: *i8= LLVMStructCreateNamed(llvm_ctx, name);
    let mut it: *i8= LLVMIntTypeInContext(llvm_ctx, (i32)w);
    let mut flds: [2]*i8; flds[0] = it; flds[1] = it;
    LLVMStructSetBody(st, flds, (u32)2, 0);
    return st;
}

// Return the LLVM named struct type for a complex number of given bit-width.
// Layout: { fN real, fN imag }
// Named so that LLVMGetStructName() returns "__complex_N" for field lookup.
fn complex_llvm_type(bw: u32, llvm_ctx: *i8) *i8 {
    let mut w: u32= (bw == 0) ? (u32)64 : bw;
    let mut name: [64]i8;
    snprintf(name, (u64)64, "__complex_%d", (i32)w);
    let mut existing: *i8= LLVMGetTypeByName2(llvm_ctx, name);
    if (existing != (i8*)0) { return existing; }
    let mut st: *i8= LLVMStructCreateNamed(llvm_ctx, name);
    let mut ft: *i8= llvm_float_for_width(w, llvm_ctx);
    let mut flds: [2]*i8; flds[0] = ft; flds[1] = ft;
    LLVMStructSetBody(st, flds, (u32)2, 0);
    return st;
}

// Map a primitive type + bit-width to an LLVMTypeRef.
fn llvm_type_of_prim(prim: i32, bw: u32, llvm_ctx: *i8) *i8 {
    if (prim == char_t)       { return LLVMInt8TypeInContext(llvm_ctx); }
    if (prim == void_t)       { return LLVMVoidTypeInContext(llvm_ctx); }
    if (prim == arb_float)    { return llvm_float_for_width(bw == 0 ? (u32)64 : bw, llvm_ctx); }
    if (prim == arb_rational) { return rational_llvm_type(bw, llvm_ctx); }
    if (prim == arb_complex)  { return complex_llvm_type(bw, llvm_ctx); }
    // arb_char_w: N-bit unsigned char
    if (prim == arb_char_w) {
        let mut w: u32= (bw == 0) ? (u32)8 : bw;
        return LLVMIntTypeInContext(llvm_ctx, (i32)w);
    }
    // arb_str_w: pointer to N-bit char (pointer type)
    if (prim == arb_str_w) {
        return LLVMPointerTypeInContext(llvm_ctx, 0);
    }
    // arb_nat: natural number ≥0 — unsigned integer of width N
    if (prim == arb_nat) {
        let mut w: u32= (bw == 0) ? (u32)32 : bw;
        return LLVMIntTypeInContext(llvm_ctx, (i32)w);
    }
    // arb_zint: integer ring ℤ — signed integer of width N (distinct from arb_int)
    if (prim == arb_zint) {
        let mut w: u32= (bw == 0) ? (u32)32 : bw;
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
    // arb_usize: pointer-sized unsigned (u64 on x64)
    if (prim == arb_usize) { return LLVMInt64TypeInContext(llvm_ctx); }
    // arb_isize: pointer-sized signed (i64 on x64)
    if (prim == arb_isize) { return LLVMInt64TypeInContext(llvm_ctx); }
    // arb_iofs: signed offset = ptr_bits+1 (i65 on x64)
    if (prim == arb_iofs)  { return LLVMIntTypeInContext(llvm_ctx, 65); }
    // arb_int, arb_uint, arb_bool: integer type
    // bw==0 means i[_]/u[_] infinite-width shorthand; use the largest practical
    // LLVM integer width (1024 bits). LLVM supports up to (1<<23)-1 bit integers.
    let mut width: u32= bw == 0 ? (u32)1024 : bw;
    return LLVMIntTypeInContext(llvm_ctx, (i32)width);
}

// Forward declarations (defined later in decls.arc / types.arc below).
fn resolve_typedef_alias(t: *parser.type_node, ctx: *ir_context) *i8;
// Generic class monomorphization — defined in decls.arc (included after types.arc).
fn ir_get_or_monomorphize_generic_class(t: *parser.type_node, ctx: *ir_context) *i8;
// memstr fat-pointer type creation — defined in decls.arc.
fn ensure_memstr_types(ctx: *ir_context) void;

// Convert a full type_node* (including pointer depth) to an LLVMTypeRef.
fn llvm_type_of(t: *parser.type_node, ctx: *ir_context) *i8 {
    if (t == (parser.type_node*)0) {
        return LLVMVoidTypeInContext(ctx.llvm_ctx);
    }

    // Error union: !void → i32 (error code only); !T → { i32, T } (error code + value).
    // The 'is_error_union' flag is set by parse_type() on '!T' prefix syntax.
    if (t.is_error_union) {
        let mut i32t_eu: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);
        // !void (pointer_depth==0 AND prim==void_t) → i32 error code only.
        // !*void, !T → { i32, T } (error code + value).
        let mut inner_is_void: bool= (t.pointer_depth == 0 && t.is_primitive && t.has_prim && t.prim == (i32)void_t);
        if (inner_is_void) {
            // !void → i32 (error code)
            return i32t_eu;
        }
        // !T → { i32, T }
        // Temporarily clear is_error_union to get the inner type
        let mut inner_copy: parser.type_node;
        inner_copy = *t;
        inner_copy.is_error_union = false;
        let mut inner_t: *i8= llvm_type_of(&inner_copy, ctx);
        // Build an anonymous struct type for this error union
        let mut eu_flds: [2]*i8;
        eu_flds[0] = i32t_eu;
        eu_flds[1] = inner_t;
        let mut eu_ty: *i8= LLVMStructTypeInContext(ctx.llvm_ctx, eu_flds, 2, 0);
        return eu_ty;
    }

    // interface NAME — passed by value as the { data_ptr, vtable_ptr } fat pointer.
    // Lowering to a bare void* instead would leave the call site handing over a
    // pointer to the concrete struct while the callee reads a fat pointer out of it,
    // so the vtable slot would be read from the object's own bytes.
    if (t.is_interface) {
        // `interface X*` is an explicit pointer — keep it opaque, as the callee is
        // expected to cast it back to a concrete type itself.
        if (t.pointer_depth == 0 && t.name != (i8*)0) {
            let mut iface_st: *i8= (i8*)0;
            if (t.type_args_len > 0) {
                iface_st = ir_get_or_monomorphize_generic_class(t, ctx);
            }
            if (iface_st == (i8*)0) { iface_st = st_map_get(&ctx.struct_types, t.name); }
            if (iface_st != (i8*)0 && LLVMGetTypeKind(iface_st) == LLVMStructTypeKind) {
                return iface_st;
            }
        }
        let mut ipt: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
        let mut idep: i32= 1;
        while (idep < t.pointer_depth) { ipt = LLVMPointerType(ipt, 0); idep = idep + 1; }
        return ipt;
    }

    // anytype — generic parameter placeholder: lower to opaque ptr at LLVM level
    if (t.is_anytype) {
        let mut pt: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
        let mut extra_d: i32= t.pointer_depth;
        let mut di: i32= 1;
        while (di < extra_d) {
            pt = LLVMPointerType(pt, 0);
            di = di + 1;
        }
        return pt;
    }

    // Function pointer: returntype(params)*
    if (t.is_func_ptr && t.fp_ret != (i8*)0) {
        let mut ret_t: *i8= llvm_type_of((parser.type_node*)t.fp_ret, ctx);

        // Build parameter type array
        let mut nparams: i32= t.fp_params_len;
        let mut param_ts: **i8= (i8**)0;
        if (nparams > 0) {
            param_ts = (i8**)arc_malloc(sizeof(i8*) * (u64)nparams);
            let mut pi: i32= 0;
            while (pi < nparams) {
                let mut pt: *parser.type_node= (parser.type_node*)t.fp_params[pi];
                param_ts[pi] = llvm_type_of(pt, ctx);
                pi = pi + 1;
            }
        }
        let mut variadic: i32= t.fp_variadic ? 1 : 0;
        let mut fn_t: *i8= LLVMFunctionType(ret_t, param_ts, nparams, variadic);
        if (param_ts != (i8**)0) { arc_free((i8*)param_ts); }
        // pointer_depth=0/1 → func ptr; depth=2+ → ptr-to-func-ptr etc.
        let mut result: *i8= LLVMPointerType(fn_t, 0);
        let mut extra: i32= t.pointer_depth - 1;
        let mut ei: i32= 0;
        while (ei < extra) {
            result = LLVMPointerType(result, 0);
            ei = ei + 1;
        }
        return result;
    }

    let mut base: *i8= (i8*)0;
    if (t.is_primitive && t.has_prim) {
        base = llvm_type_of_prim(t.prim, (u32)t.bit_width, ctx.llvm_ctx);
        // Register struct meta for complex and rational types so field access (.re/.im, .num/.den) works.
        if ((t.prim == arb_complex || t.prim == arb_rational) && base != (i8*)0) {
            let mut bw: u32= (t.bit_width == 0) ? (u32)64 : (u32)t.bit_width;
            let mut sname: [64]i8;
            if (t.prim == arb_complex)  { snprintf(sname, (u64)64, "__complex_%d",  (i32)bw); }
            else                         { snprintf(sname, (u64)64, "__rational_%d", (i32)bw); }
            // Register in struct_types if not already there
            if (st_map_get(&ctx.struct_types, sname) == (i8*)0) {
                st_map_set(&ctx.struct_types, lexer.str_dup(sname), base);
                let mut sm: struct_meta;
                sm.name = lexer.str_dup(sname);
                name_list_init(&sm.field_names);
                type_list_init(&sm.field_types);
                bool_list_init(&sm.field_unsigned);
                type_list_init(&sm.field_pointee);
                name_list_init(&sm.field_pointee_names);
                sm.is_union  = false;
                sm.is_istruc = false;
                let mut elem_t: *i8= LLVMStructGetTypeAtIndex(base, (u32)0);
                if (t.prim == arb_complex) {
                    name_list_push(&sm.field_names, lexer.str_dup("re"));
                    type_list_push(&sm.field_types, elem_t);
                    bool_list_push(&sm.field_unsigned, false);
                    type_list_push(&sm.field_pointee, (i8*)0);
                    name_list_push(&sm.field_pointee_names, (i8*)0);
                    name_list_push(&sm.field_names, lexer.str_dup("im"));
                    type_list_push(&sm.field_types, elem_t);
                    bool_list_push(&sm.field_unsigned, false);
                    type_list_push(&sm.field_pointee, (i8*)0);
                    name_list_push(&sm.field_pointee_names, (i8*)0);
                } else {
                    name_list_push(&sm.field_names, lexer.str_dup("num"));
                    type_list_push(&sm.field_types, elem_t);
                    bool_list_push(&sm.field_unsigned, false);
                    type_list_push(&sm.field_pointee, (i8*)0);
                    name_list_push(&sm.field_pointee_names, (i8*)0);
                    name_list_push(&sm.field_names, lexer.str_dup("den"));
                    type_list_push(&sm.field_types, elem_t);
                    bool_list_push(&sm.field_unsigned, false);
                    type_list_push(&sm.field_pointee, (i8*)0);
                    name_list_push(&sm.field_pointee_names, (i8*)0);
                }
                struct_meta_vec_push(&ctx.struct_meta_tbl, sm);
            }
        }
    } else {
        let mut name: *i8= t.name;
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
        let mut found_struct: *i8= (i8*)0;
        if (base == (i8*)0) { found_struct = st_map_get(&ctx.struct_types, name); }
        if (found_struct != (i8*)0) {
            base = found_struct;
        } else if (base == (i8*)0) {
            // Check typedef aliases
            let mut alias_tn: *i8= typedef_map_get(&ctx.typedef_aliases, name);
            if (alias_tn != (i8*)0) {
                let mut resolved_tn: *parser.type_node= (parser.type_node*)alias_tn;
                let mut resolved: *i8= llvm_type_of(resolved_tn, ctx);
                // Apply pointer depth on top of resolved
                let mut pi: i32= 0;
                while (pi < t.pointer_depth) {
                    resolved = LLVMPointerType(resolved, 0);
                    pi = pi + 1;
                }
                return resolved;
            }
            // Try namespace-qualified lookup
            if (ctx.current_namespace != (i8*)0) {
                let mut ns_name: [512]i8;
                snprintf(ns_name, (u64)512, "%s__NS_%s", ctx.current_namespace, name);
                found_struct = st_map_get(&ctx.struct_types, ns_name);
                if (found_struct != (i8*)0) {
                    base = found_struct;
                }
            }
            if (base == (i8*)0) {
                // Check type parameter bindings (for generic instantiation)
                let mut tp_t: *i8= st_map_get(&ctx.type_param_bindings, name);
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
    let mut pi: i32= 0;
    while (pi < t.pointer_depth) {
        base = LLVMPointerType(base, 0);
        pi = pi + 1;
    }

    // Array type
    if (t.array_size_ptr != (i8*)0) {
        let mut sz_expr: *parser.expr_node= (parser.expr_node*)t.array_size_ptr;
        let mut n: u64= 0;
        if (sz_expr.kind == ek_int_lit) {
            n = (u64)sz_expr.int_val;
        } else if (sz_expr.kind == ek_identifier && sz_expr.str_val != (i8*)0) {
            // Try to look up constexpr value
            let mut cv: *i8= sv_map_get(&ctx.constexpr_int_vals_map, sz_expr.str_val);
            if (cv != (i8*)0) {
                n = (u64)(i64)cv;
            }
        }
        return LLVMArrayType2(base, n);
    }

    return base;
}

// Returns the bare LLVMFunctionType for a func-ptr type node (no pointer wrapper).
// Used to store the function type for indirect-call resolution in opaque-pointer mode.
fn llvm_func_type_of(t: *parser.type_node, ctx: *ir_context) *i8 {
    if (t == (parser.type_node*)0) { return (i8*)0; }
    if (!t.is_func_ptr || t.fp_ret == (i8*)0) { return (i8*)0; }
    let mut ret_t: *i8= llvm_type_of((parser.type_node*)t.fp_ret, ctx);
    let mut nparams: i32= t.fp_params_len;
    let mut param_ts: **i8= (i8**)0;
    if (nparams > 0) {
        param_ts = (i8**)arc_malloc(sizeof(i8*) * (u64)nparams);
        let mut pi: i32= 0;
        while (pi < nparams) {
            let mut pt: *parser.type_node= (parser.type_node*)t.fp_params[pi];
            param_ts[pi] = llvm_type_of(pt, ctx);
            pi = pi + 1;
        }
    }
    let mut variadic: i32= t.fp_variadic ? 1 : 0;
    let mut fn_t: *i8= LLVMFunctionType(ret_t, param_ts, nparams, variadic);
    if (param_ts != (i8**)0) { arc_free((i8*)param_ts); }
    return fn_t;
}

// Resolve typedef alias: returns the underlying type_node.
fn resolve_typedef_alias_node(t: *parser.type_node, ctx: *ir_context) *parser.type_node {
    if (t == (parser.type_node*)0) { return (parser.type_node*)0; }
    if (t.is_primitive) { return t; }
    if (t.pointer_depth > 0) { return t; }
    if (t.name == (i8*)0) { return t; }
    let mut alias_tn: *i8= typedef_map_get(&ctx.typedef_aliases, t.name);
    if (alias_tn == (i8*)0) { return t; }
    return resolve_typedef_alias_node((parser.type_node*)alias_tn, ctx);
}

// Returns true when an LLVM type is a floating-point kind.
fn llvm_is_float(t: *i8) bool {
    let mut k: i32= LLVMGetTypeKind(t);
    return k == LLVMHalfTypeKind   || k == LLVMBFloatTypeKind  ||
           k == LLVMFloatTypeKind  || k == LLVMDoubleTypeKind  ||
           k == LLVMX86_FP80TypeKind || k == LLVMFP128TypeKind;
}

} // namespace ir
