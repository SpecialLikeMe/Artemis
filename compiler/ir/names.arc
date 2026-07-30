// Name mangling for the Artemis self-hosting compiler.

namespace ir {

// Encode a single type_node into a short string for name mangling.
// Returns a heap-allocated string.
fn mangle_type(t: *parser.type_node) *i8 {
    if (t == (parser.type_node*)0) { return lexer.str_dup("v"); }
    if (t.is_func_ptr) {
        // Encode return type and parameter types to disambiguate overloads
        let mut buf: [512]i8;
        let mut ret_m: *i8= mangle_type((parser.type_node*)t.fp_ret);
        afmt(buf, (u64)512, "FP%s_", .{ ret_m });
        arc_free(ret_m);
        let mut pi: i32= 0;
        while (pi < t.fp_params_len) {
            let mut pm: *i8= mangle_type(((parser.type_node**)t.fp_params)[pi]);
            let mut tmp: [512]i8;
            afmt(tmp, (u64)512, "%s%s", .{ buf, pm });
            afmt(buf, (u64)512, "%s", .{ tmp });
            arc_free(pm);
            pi = pi + 1;
        }
        return lexer.str_dup(buf);
    }

    let mut buf: [256]i8;
    buf[0] = 0;

    // Pointer prefix
    let mut pi: i32= 0;
    while (pi < t.pointer_depth) {
        let mut tmp: [256]i8;
        afmt(tmp, (u64)256, "P%s", .{ buf });
        afmt(buf, (u64)256, "%s", .{ tmp });
        pi = pi + 1;
    }

    if (t.is_primitive && t.has_prim) {
        let mut suffix: [64]i8;
        if (t.prim == void_t)         { afmt(suffix, (u64)64, "v", .{}); }
        else if (t.prim == char_t)    { afmt(suffix, (u64)64, "c", .{}); }
        else if (t.prim == arb_int)   { afmt(suffix, (u64)64, "i%d", .{ (i32)t.bit_width }); }
        else if (t.prim == arb_uint)  { afmt(suffix, (u64)64, "u%d", .{ (i32)t.bit_width }); }
        else if (t.prim == arb_float) { afmt(suffix, (u64)64, "f%d", .{ (i32)t.bit_width }); }
        else if (t.prim == arb_bool)  { afmt(suffix, (u64)64, "b%d", .{ (i32)t.bit_width }); }
        else if (t.prim == arb_nat)   { afmt(suffix, (u64)64, "n%d", .{ (i32)t.bit_width }); }
        else if (t.prim == arb_zint)  { afmt(suffix, (u64)64, "z%d", .{ (i32)t.bit_width }); }
        else if (t.prim == arb_real)  { afmt(suffix, (u64)64, "r%d", .{ (i32)t.bit_width }); }
        else if (t.prim == arb_alg)   { afmt(suffix, (u64)64, "a%d", .{ (i32)t.bit_width }); }
        else if (t.prim == arb_usize) { afmt(suffix, (u64)64, "us", .{}); }
        else if (t.prim == arb_isize) { afmt(suffix, (u64)64, "is", .{}); }
        else if (t.prim == arb_iofs)  { afmt(suffix, (u64)64, "io", .{}); }
        else if (t.prim == arb_char_w){ afmt(suffix, (u64)64, "cw%d", .{ (i32)t.bit_width }); }
        else if (t.prim == arb_str_w) { afmt(suffix, (u64)64, "sw%d", .{ (i32)t.bit_width }); }
        else if (t.prim == arb_rational) { afmt(suffix, (u64)64, "q%d", .{ (i32)t.bit_width }); }
        else if (t.prim == arb_complex)  { afmt(suffix, (u64)64, "cx%d", .{ (i32)t.bit_width }); }
        else { afmt(suffix, (u64)64, "X%d", .{ (i32)t.prim }); } // unknown prim: use numeric id
        let mut full: [256]i8;
        afmt(full, (u64)256, "%s%s", .{ buf, suffix });
        return lexer.str_dup(full);
    }

    if (t.name != (i8*)0) {
        let mut full: [256]i8;
        afmt(full, (u64)256, "%s%s", .{ buf, t.name });
        return lexer.str_dup(full);
    }

    let mut full: [256]i8;
    afmt(full, (u64)256, "%s?", .{ buf });
    return lexer.str_dup(full);
}

// Build the mangled name for an overloaded function: funcname__type1_type2_...
// Returns a heap-allocated string.
fn build_mangled_name(base: *i8, params: *parser.param_decl, params_len: i32) *i8 {
    let mut buf: [1024]i8;
    afmt(buf, (u64)1024, "%s__", .{ base });

    let mut i: i32= 0;
    while (i < params_len) {
        if (i > 0) {
            let mut tmp: [1024]i8;
            afmt(tmp, (u64)1024, "%s_", .{ buf });
            afmt(buf, (u64)1024, "%s", .{ tmp });
        }
        let mut mt: *i8= mangle_type(params[i].type);
        let mut tmp: [1024]i8;
        afmt(tmp, (u64)1024, "%s%s", .{ buf, mt });
        afmt(buf, (u64)1024, "%s", .{ tmp });
        arc_free(mt);
        i = i + 1;
    }
    return lexer.str_dup(buf);
}

// Encode a resolved LLVM type into a short mangling key.
//
// Generic instantiation keys must be built from the *resolved* type, not the source
// spelling: inside a generic method `self: *Box<T>` spells its argument as `T` for
// every instantiation, so mangling the AST would give Box<i32> and Box<f64> the same
// key and the second instantiation would silently reuse the first one's layout.
fn mangle_llvm_type(ty: *i8) *i8 {
    if (ty == (i8*)0) { return lexer.str_dup("v"); }
    let mut buf: [128]i8;
    let mut k: i32= LLVMGetTypeKind(ty);
    if (k == LLVMIntegerTypeKind) {
        afmt(buf, (u64)128, "i%u", .{ LLVMGetIntTypeWidth(ty) });
    } else if (k == LLVMHalfTypeKind)   { afmt(buf, (u64)128, "f16", .{}); }
    else if (k == LLVMFloatTypeKind)    { afmt(buf, (u64)128, "f32", .{}); }
    else if (k == LLVMDoubleTypeKind)   { afmt(buf, (u64)128, "f64", .{}); }
    else if (k == LLVMX86_FP80TypeKind) { afmt(buf, (u64)128, "f80", .{}); }
    else if (k == LLVMPointerTypeKind)  { afmt(buf, (u64)128, "P", .{}); }
    else if (k == LLVMVoidTypeKind)     { afmt(buf, (u64)128, "v", .{}); }
    else if (k == LLVMArrayTypeKind) {
        let mut em: *i8= mangle_llvm_type(LLVMGetElementType(ty));
        afmt(buf, (u64)128, "A%u%s", .{ LLVMGetArrayLength(ty), em });
        arc_free(em);
    } else if (k == LLVMStructTypeKind) {
        let mut sn: *i8= LLVMGetStructName(ty);
        if (sn != (i8*)0) { afmt(buf, (u64)128, "S%s", .{ sn }); }
        else              { afmt(buf, (u64)128, "S%u", .{ LLVMCountStructElementTypes(ty) }); }
    } else if (k == LLVMFunctionTypeKind) { afmt(buf, (u64)128, "F", .{}); }
    else { afmt(buf, (u64)128, "T%d", .{ k }); }
    return lexer.str_dup(buf);
}

// Get the IR name for a func_decl.
// The symbol this function is emitted as. @link_name overrides it, which is how a
// raw FFI binding and its safe wrapper can coexist under different symbols while the
// wrapper keeps the plain Arc name that call sites use.
//
// This is deliberately *not* the key used for call resolution — see ir_func_key.
fn ir_func_name(fd: *parser.func_decl) *i8 {
    if (fd.link_name != (i8*)0) { return fd.link_name; }
    if (fd.is_extern_c) { return fd.name; }
    if (fd.mangled_name != (i8*)0) { return fd.mangled_name; }
    return fd.name;
}

// The name call sites resolve by. Overload mangling participates (callers resolve to
// the mangled name), but @link_name must not: it only renames the emitted symbol.
fn ir_func_key(fd: *parser.func_decl) *i8 {
    if (fd.is_extern_c) { return fd.name; }
    if (fd.mangled_name != (i8*)0) { return fd.mangled_name; }
    return fd.name;
}

} // namespace ir
