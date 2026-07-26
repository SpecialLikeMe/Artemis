// PASS: @typeinfo returns correct variant and bits for primitive types
// Int=2, Uint=3, Pointer=9
pub fn main() i32 {
    // i32: Int variant (tag 2), bits=32, is_signed=1
    let t_i32 = @typeinfo(i32);
    if (t_i32.__tag != 2) { return 1; }
    let mut i32_bits: i64 = 0;
    let mut i32_signed: i64 = 0;
    match (*t_i32) {
        type_info::Int(bits_v, signed_v) => { i32_bits = bits_v; i32_signed = signed_v; }
        _ => { return 2; }
    }
    if (i32_bits != 32) { return 2; }
    if (i32_signed != 1) { return 3; }

    // u8: Uint variant (tag 3), bits=8, is_signed=0
    let t_u8 = @typeinfo(u8);
    if (t_u8.__tag != 3) { return 4; }
    let mut u8_bits: i64 = 0;
    let mut u8_signed: i64 = 1;
    match (*t_u8) {
        type_info::Uint(ubits, usigned) => { u8_bits = ubits; u8_signed = usigned; }
        _ => { return 5; }
    }
    if (u8_bits != 8)   { return 5; }
    if (u8_signed != 0) { return 6; }

    // pointer: Pointer variant (tag 9)
    let t_ptr = @typeinfo(*i32);
    if (t_ptr.__tag != 9) { return 7; }

    return 0;
}
