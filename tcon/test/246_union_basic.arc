// PASS: union fields share memory.
union IntFloat {
    let a: i32;
    let b: f32;
}
pub fn main() i32 {
    let mut u: IntFloat;
    u.a = 42;
    if (u.a != 42) { return 1; }

    // Shared memory: writing via one field, reading via another
    u.a = 0x3f800000;  // IEEE 754 bits for 1.0f
    // Reading back the integer bits should give the same value
    let mut bits: i32= u.a;
    if (bits != 0x3f800000) { return 2; }

    return 0;
}
