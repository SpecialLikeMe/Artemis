i32 main() {
    i32 a = 0xFF;
    i32 b = 0x0F;
    i32 c = a & b;
    if (c != 0x0F) { return 1; }
    i32 d = 0xAA & 0x55;
    if (d != 0)    { return 2; }
    return 0;
}
