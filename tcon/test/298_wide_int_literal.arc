// PASS: integer literals wider than 64 bits are stored precisely using
// string-based LLVM constant construction (no i64 overflow).
pub fn main() i32 {
    // INT128_MAX: positive, must not lose precision to i64 truncation
    let mut a: i128 = 170141183460469231731687303715884105727;
    if (a <= (i128)0) { return 1; }
    // Adding 1 to INT128_MAX wraps to negative (INT128_MIN) in two's complement
    let mut b: i128 = a + (i128)1;
    if (b >= (i128)0) { return 2; }
    // A large positive i128 well within range
    let mut c: i128 = 100000000000000000000000000000000000000;
    if (c <= (i128)0) { return 3; }
    if (c > a) { return 4; }
    return 0;
}
