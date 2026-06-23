i32 main() {
    i32 a = 0xFF;
    i32 b = 0x0F;
    i32 c = a ^ b;
    if (c != 0xF0) { return 1; }
    i32 x = 5 ^ 5;
    if (x != 0)    { return 2; }
    return 0;
}
