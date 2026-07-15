comptime type T = i32;
i32 main() {
    T x = 42;
    if (x != 42) { return 1; }
    return 0;
}
