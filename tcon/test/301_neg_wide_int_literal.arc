// PASS: negative wide integer literals (>64 bit) are stored precisely.
// -2^127 = INT128_MIN must be exact, not truncated to negated LLONG_MAX.
pub fn main() i32 {
    // INT128_MIN: exact -2^127
    let mut a: i128 = -170141183460469231731687303715884105728;
    if (a >= (i128)0) { return 1; }
    // a + 1 should still be negative (well within i128 range)
    let mut b: i128 = a + (i128)1;
    if (b >= (i128)0) { return 2; }
    // a - INT128_MAX should be exactly -1
    let mut c: i128 = a + (i128)170141183460469231731687303715884105727;
    if (c != (i128)-1) { return 3; }
    return 0;
}
