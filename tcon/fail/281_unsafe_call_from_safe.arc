// FAIL: calling an @unsafe function from a safe context is rejected.
@unsafe extern fn strlen(s: *const i8) u64;
pub fn main() i32 {
    let mut n: u64= strlen("hello");   // no @unsafe context
    return (i32)n;
}
