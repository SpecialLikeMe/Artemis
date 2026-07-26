// FAIL: __asm__ is opaque to every analysis, so it requires an unsafe context.
pub fn main() i32 {
    __asm__ { "nop" }
    return 0;
}
