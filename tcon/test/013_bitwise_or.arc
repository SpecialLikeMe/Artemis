i32 main() {
    i32 a = 0xF0;
    i32 b = 0x0F;
    i32 c = a | b;
    if (c != 0xFF) { return 1; }
    i32 d = 0 | 42;
    if (d != 42)   { return 2; }
    return 0;
}
