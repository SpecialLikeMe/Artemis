i32 main() {
    i32 x = -5;
    i32 y = +x;
    if (y != -5) { return 1; }
    i32 z = +42;
    if (z != 42) { return 2; }
    return 0;
}
