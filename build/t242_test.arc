i32 main() {
    comptime type T = i32;
    T x = 42;
    if (x != 42) { return 1; }
    return 0;
}
