// PASS: explicit cast allows mixing integer types in arithmetic
pub fn main() i32 {
    let x: u8 = 5;
    let y: i32 = -10;
    let z: i32 = (x as i32) + y;
    if (z != -5) { return 1; }
    // Literals are untyped and can be mixed with any integer type
    let a: u8 = 3;
    let b: u8 = a + 2;  // literal 2 is fine with u8
    if (b != 5) { return 2; }
    let c: i64 = 100;
    let d: i64 = c + 1;  // literal 1 is fine with i64
    if (d != 101) { return 3; }
    return 0;
}
