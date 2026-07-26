// PASS: bN types are arbitrary-width booleans; widening casts use zero-extension.
pub fn main() i32 {
    // b2 stores 2-bit unsigned value: 3 = 0b11
    let mut a: b2 = (b2)3;
    if ((i32)a != 3) { return 1; }
    // b4 stores 4-bit value: 15 = 0b1111
    let mut b: b4 = (b4)15;
    if ((i32)b != 15) { return 2; }
    // b7 stores 7-bit value: 127 = 0b1111111
    let mut c: b7 = (b7)127;
    if ((i32)c != 127) { return 3; }
    // b8 stores 8-bit value: 200
    let mut d: b8 = (b8)200;
    if ((i32)d != 200) { return 4; }
    // b2 bitwise AND
    let mut e2: b2 = (b2)(a & (b2)1);
    if ((i32)e2 != 1) { return 5; }
    return 0;
}
