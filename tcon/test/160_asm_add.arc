// Inline ASM: add two integers using Intel-syntax asm with constraints
pub @unsafe fn main() i32 {
    let mut a: i32= 7;
    let mut b: i32= 5;
    let mut result: i32= 0;
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
