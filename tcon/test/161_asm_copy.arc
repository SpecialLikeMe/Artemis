// Inline ASM: copy a value via register
pub fn main() i32 {
    let mut src: i32= 99;
    let mut dst: i32= 0;
    __asm__ {
        mov %dst, %src
        : "r"(src)
        : "=r"(dst)
    }
    if (dst != 99) { return 1; }
    return 0;
}
