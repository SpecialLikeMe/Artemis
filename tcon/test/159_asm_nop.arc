// Inline ASM: no-op with no constraints
pub @unsafe fn main() i32 {
    let mut x: i32= 5;
    __asm__ { nop }
    if (x != 5) { return 1; }
    return 0;
}
