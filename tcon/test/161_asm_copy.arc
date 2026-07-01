// Inline ASM: copy a value via register
i32 main() {
    i32 src = 99;
    i32 dst = 0;
    __asm__ {
        mov %dst, %src
        : "r"(src)
        : "=r"(dst)
    }
    if (dst != 99) { return 1; }
    return 0;
}
