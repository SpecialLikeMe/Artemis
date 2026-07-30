// Type utilities for the Artemis self-hosting compiler analyzer.

namespace analysis {

// Convert a prim_type_t value to a display string.
fn prim_to_str(prim: i32, bit_width: u32) *i8 {
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
fn type_to_str(t: *parser.type_node) *i8 {
    if (t == (parser.type_node*)0) { return "void"; }
    let mut buf: [256]i8;
    if (t.is_primitive && t.has_prim) {
        let mut base: *i8= prim_to_str(t.prim, (u32)t.bit_width);
        let mut depth: i32= t.pointer_depth;
        if (depth == 0) {
            return lexer.str_dup(base);
        }
        afmt(buf, (u64)256, "%s", .{ base });
        let mut i: i32= 0;
        while (i < depth) {
            let mut tmp: [256]i8;
            afmt(tmp, (u64)256, "%s*", .{ buf });
            afmt(buf, (u64)256, "%s", .{ tmp });
            i = i + 1;
        }
        return lexer.str_dup(buf);
    }
    if (t.name != (i8*)0) {
        afmt(buf, (u64)256, "%s", .{ t.name });
        let mut i: i32= 0;
        while (i < t.pointer_depth) {
            let mut tmp: [256]i8;
            afmt(tmp, (u64)256, "%s*", .{ buf });
            afmt(buf, (u64)256, "%s", .{ tmp });
            i = i + 1;
        }
        return lexer.str_dup(buf);
    }
    return "unknown";
}

// Return true if a prim type is an integer (not float, not void).
fn is_int_prim(prim: i32) bool {
    if (prim == char_t)   { return true; }
    if (prim == arb_int)  { return true; }
    if (prim == arb_uint) { return true; }
    if (prim == arb_bool) { return true; }
    return false;
}

// Return true if a prim type is floating point.
fn is_float_prim(prim: i32) bool {
    return prim == arb_float;
}

// Return true if a type_node is a pointer (pointer_depth > 0).
fn is_pointer_type(t: *parser.type_node) bool {
    if (t == (parser.type_node*)0) { return false; }
    return t.pointer_depth > 0;
}

// Return true if a type_node is unsigned.
fn is_unsigned_type(t: *parser.type_node) bool {
    if (t == (parser.type_node*)0) { return false; }
    if (!t.is_primitive) { return false; }
    if (t.pointer_depth > 0) { return false; }
    return t.prim == arb_uint || t.prim == arb_bool;
}

// Return true if two type_nodes are equal (shallow).
fn types_equal(a: *parser.type_node, b: *parser.type_node) bool {
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
