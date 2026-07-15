// Type utilities for the Artemis self-hosting compiler analyzer.

namespace analysis {

// Convert a prim_type_t value to a display string.
i8* prim_to_str(i32 prim, u32 bit_width) {
    if (prim == char_t)    { return "i8"; }
    if (prim == void_t)    { return "void"; }
    if (prim == arb_bool)  { return "bool"; }
    if (prim == arb_float) {
        if (bit_width == 32) { return "f32"; }
        if (bit_width == 64) { return "f64"; }
        return "f64";
    }
    if (prim == arb_uint) {
        if (bit_width == 8)  { return "u8"; }
        if (bit_width == 16) { return "u16"; }
        if (bit_width == 32) { return "u32"; }
        if (bit_width == 64) { return "u64"; }
        return "uN";
    }
    // arb_int
    if (bit_width == 8)  { return "i8"; }
    if (bit_width == 16) { return "i16"; }
    if (bit_width == 32) { return "i32"; }
    if (bit_width == 64) { return "i64"; }
    return "iN";
}

// Convert a type_node to a display string (heap-allocated).
i8* type_to_str(parser.type_node* t) {
    if (t == (parser.type_node*)0) { return "void"; }
    i8 buf[256];
    if (t.is_primitive && t.has_prim) {
        i8* base = prim_to_str(t.prim, (u32)t.bit_width);
        i32 depth = t.pointer_depth;
        if (depth == 0) {
            return lexer.str_dup(base);
        }
        snprintf(buf, (u64)256, "%s", base);
        i32 i = 0;
        while (i < depth) {
            i8 tmp[256];
            snprintf(tmp, (u64)256, "%s*", buf);
            snprintf(buf, (u64)256, "%s", tmp);
            i = i + 1;
        }
        return lexer.str_dup(buf);
    }
    if (t.name != (i8*)0) {
        snprintf(buf, (u64)256, "%s", t.name);
        i32 i = 0;
        while (i < t.pointer_depth) {
            i8 tmp[256];
            snprintf(tmp, (u64)256, "%s*", buf);
            snprintf(buf, (u64)256, "%s", tmp);
            i = i + 1;
        }
        return lexer.str_dup(buf);
    }
    return "unknown";
}

// Return true if a prim type is an integer (not float, not void).
bool is_int_prim(i32 prim) {
    if (prim == char_t)   { return true; }
    if (prim == arb_int)  { return true; }
    if (prim == arb_uint) { return true; }
    if (prim == arb_bool) { return true; }
    return false;
}

// Return true if a prim type is floating point.
bool is_float_prim(i32 prim) {
    return prim == arb_float;
}

// Return true if a type_node is a pointer (pointer_depth > 0).
bool is_pointer_type(parser.type_node* t) {
    if (t == (parser.type_node*)0) { return false; }
    return t.pointer_depth > 0;
}

// Return true if a type_node is unsigned.
bool is_unsigned_type(parser.type_node* t) {
    if (t == (parser.type_node*)0) { return false; }
    if (!t.is_primitive) { return false; }
    if (t.pointer_depth > 0) { return false; }
    return t.prim == arb_uint || t.prim == arb_bool;
}

// Return true if two type_nodes are equal (shallow).
bool types_equal(parser.type_node* a, parser.type_node* b) {
    if (a == (parser.type_node*)0 && b == (parser.type_node*)0) { return true; }
    if (a == (parser.type_node*)0 || b == (parser.type_node*)0) { return false; }
    if (a.is_primitive != b.is_primitive) { return false; }
    if (a.pointer_depth != b.pointer_depth) { return false; }
    if (a.is_primitive) {
        if (a.prim != b.prim) { return false; }
        if (a.bit_width != b.bit_width) { return false; }
        return true;
    }
    if (a.name != (i8*)0 && b.name != (i8*)0) {
        return strcmp(a.name, b.name) == 0;
    }
    return false;
}

} // namespace analysis
