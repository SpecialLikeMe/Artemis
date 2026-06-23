i32 main() {
    i32 a = 0;
    i32 b = 0;
    i32 c = 0;
    a = b = c = 42;
    if (a != 42) { return 1; }
    if (b != 42) { return 2; }
    if (c != 42) { return 3; }
    return 0;
}
