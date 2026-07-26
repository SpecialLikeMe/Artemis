// PASS: @typeinfo on primitive types — returns valid type_info ADT with correct variants.
// Int=2, Uint=3, Float=4
pub fn main() i32 {
    // i32 -> Int variant (tag 2); bits=32
    let mut ti: *type_info = @typeinfo(i32);
    if (ti == (type_info*)0) { return 1; }
    if (ti.__tag != 2) { return 2; }
    let mut i32_bits: i64 = 0;
    match (*ti) {
        type_info::Int(bits_v, signed_v) => { i32_bits = bits_v; }
        _ => { return 3; }
    }
    if (i32_bits != 32) { return 3; }

    // f64 -> Float variant (tag 4); bits=64
    let mut tf: *type_info = @typeinfo(f64);
    if (tf == (type_info*)0) { return 4; }
    if (tf.__tag != 4) { return 5; }
    let mut f64_bits: i64 = 0;
    match (*tf) {
        type_info::Float(fbits) => { f64_bits = fbits; }
        _ => { return 6; }
    }
    if (f64_bits != 64) { return 6; }

    // u8 -> Uint variant (tag 3); bits=8
    let mut tu: *type_info = @typeinfo(u8);
    if (tu == (type_info*)0) { return 7; }
    if (tu.__tag != 3) { return 8; }
    let mut u8_bits: i64 = 0;
    match (*tu) {
        type_info::Uint(ubits, usigned) => { u8_bits = ubits; }
        _ => { return 9; }
    }
    if (u8_bits != 8) { return 9; }

    return 0;
}
