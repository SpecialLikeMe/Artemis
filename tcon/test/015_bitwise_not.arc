i32 main() {
    i8 a = 0;
    i8 b = ~a;
    if (b != -1) { return 1; }
    i32 c = ~0;
    if (c != -1) { return 2; }
    return 0;
}
