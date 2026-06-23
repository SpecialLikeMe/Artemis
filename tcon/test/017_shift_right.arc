i32 main() {
    i32 a = 128;
    i32 b = a >> 3;
    if (b != 16)  { return 1; }
    u32 c = 256;
    u32 d = c >> 4;
    if (d != 16)  { return 2; }
    return 0;
}
