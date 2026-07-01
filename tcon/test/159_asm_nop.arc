// Inline ASM: no-op with no constraints
i32 main() {
    i32 x = 5;
    __asm__ { nop }
    if (x != 5) { return 1; }
    return 0;
}
