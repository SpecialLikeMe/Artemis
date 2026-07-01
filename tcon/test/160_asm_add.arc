// Inline ASM: add two integers using Intel-syntax asm with constraints
i32 main() {
    i32 a = 7;
    i32 b = 5;
    i32 result = 0;
    __asm__ {
        mov eax, %a
        add eax, %b
        mov %result, eax
        : "r"(a), "r"(b)
        : "=r"(result)
        : "eax"
    }
    if (result != 12) { return 1; }
    return 0;
}
