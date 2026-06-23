i32 main() {
    i64 a = 1000000000;
    i64 b = 2000000000;
    i64 c = a + b;
    if (c != 3000000000) { return 1; }
    i64 d = b - a;
    if (d != 1000000000) { return 2; }
    return 0;
}
