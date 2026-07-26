// Test @typeinfo builtin for primitive types — ADT enum variant check.
// Uses .__tag for quick checks; Int=2, Uint=3, Float=4.
@unsafe extern fn puts(s: *i8) i32;

pub @unsafe fn main() i32 {
    let mut ti: *type_info = @typeinfo(i32);
    if (ti != (type_info*)0) { puts("PASS"); } else { puts("FAIL null"); return 1; }
    if (ti.__tag == 2) { puts("PASS"); } else { puts("FAIL kind"); return 2; }  // Int=2

    // Extract bits via pattern match
    let mut got_bits: i64 = 0;
    match (*ti) {
        type_info::Int(bits_v, signed_v) => { got_bits = bits_v; }
        _ => { puts("FAIL not Int"); return 3; }
    }
    if (got_bits == 32) { puts("PASS"); } else { puts("FAIL bits"); return 3; }

    let mut tu: *type_info = @typeinfo(u8);
    let mut u8_bits: i64 = 0;
    match (*tu) {
        type_info::Uint(ubits, usigned) => { u8_bits = ubits; }
        _ => { return 5; }
    }
    if (u8_bits == 8) { puts("PASS"); } else { puts("FAIL u8 bits"); return 5; }
    puts("PASS");

    return 0;
}
