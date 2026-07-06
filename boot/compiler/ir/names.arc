// Name mangling for the Artemis self-hosting compiler.

namespace ir {

// Encode a single type_node into a short string for name mangling.
// Returns a heap-allocated string.
i8* mangle_type(parser.type_node* t) {
    if (t == (parser.type_node*)0) { return lexer.str_dup("v"); }
    if (t.is_func_ptr) { return lexer.str_dup("FP"); }

    i8 buf[256];
    buf[0] = 0;

    // Pointer prefix
    i32 pi = 0;
    while (pi < t.pointer_depth) {
        i8 tmp[256];
        snprintf(tmp, (u64)256, "P%s", buf);
        snprintf(buf, (u64)256, "%s", tmp);
        pi = pi + 1;
    }

    if (t.is_primitive && t.has_prim) {
        i8 suffix[64];
        if (t.prim == void_t)    { snprintf(suffix, (u64)64, "v"); }
        else if (t.prim == char_t)    { snprintf(suffix, (u64)64, "c"); }
        else if (t.prim == arb_int)   { snprintf(suffix, (u64)64, "i%d", (i32)t.bit_width); }
        else if (t.prim == arb_uint)  { snprintf(suffix, (u64)64, "u%d", (i32)t.bit_width); }
        else if (t.prim == arb_float) { snprintf(suffix, (u64)64, "f%d", (i32)t.bit_width); }
        else if (t.prim == arb_bool)  { snprintf(suffix, (u64)64, "b%d", (i32)t.bit_width); }
        else { snprintf(suffix, (u64)64, "?"); }
        i8 full[256];
        snprintf(full, (u64)256, "%s%s", buf, suffix);
        return lexer.str_dup(full);
    }

    if (t.name != (i8*)0) {
        i8 full[256];
        snprintf(full, (u64)256, "%s%s", buf, t.name);
        return lexer.str_dup(full);
    }

    i8 full[256];
    snprintf(full, (u64)256, "%s?", buf);
    return lexer.str_dup(full);
}

// Build the mangled name for an overloaded function: funcname__type1_type2_...
// Returns a heap-allocated string.
i8* build_mangled_name(i8* base, parser.param_decl* params, i32 params_len) {
    i8 buf[1024];
    snprintf(buf, (u64)1024, "%s__", base);

    i32 i = 0;
    while (i < params_len) {
        if (i > 0) {
            i8 tmp[1024];
            snprintf(tmp, (u64)1024, "%s_", buf);
            snprintf(buf, (u64)1024, "%s", tmp);
        }
        i8* mt = mangle_type(params[i].type);
        i8 tmp[1024];
        snprintf(tmp, (u64)1024, "%s%s", buf, mt);
        snprintf(buf, (u64)1024, "%s", tmp);
        free(mt);
        i = i + 1;
    }
    return lexer.str_dup(buf);
}

// Get the IR name for a func_decl.
i8* ir_func_name(parser.func_decl* fd) {
    if (fd.is_extern_c) { return fd.name; }
    if (fd.mangled_name != (i8*)0) { return fd.mangled_name; }
    if (fd.is_overloaded) {
        return build_mangled_name(fd.name, fd.params, fd.params_len);
    }
    return fd.name;
}

} // namespace ir
