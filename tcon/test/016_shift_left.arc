i32 main() {
    i32 a = 1;
    i32 b = a << 4;
    if (b != 16)  { return 1; }
    i32 c = 3 << 3;
    if (c != 24)  { return 2; }
    return 0;
}
