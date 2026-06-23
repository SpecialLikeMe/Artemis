i32 main() {
    i32 x = 0;
    if (sizeof(x) != 4) { return 1; }
    i64 y = 0;
    if (sizeof(y) != 8) { return 2; }
    i8  z = 0;
    if (sizeof(z) != 1) { return 3; }
    return 0;
}
