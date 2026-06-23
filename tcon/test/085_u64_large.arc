i32 main() {
    u64 a = 4000000000;
    u64 b = 4000000000;
    u64 c = a + b;
    if (c != 8000000000) { return 1; }
    u64 d = c / 2;
    if (d != 4000000000) { return 2; }
    return 0;
}
