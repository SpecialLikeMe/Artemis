T pick<T>(T a, T b) { return a + b; }
i32 main() {
    i32 a = pick(40, 2);
    if (a != 42) { return 1; }
    i64 b = pick((i64)100, (i64)23);
    if (b != 123) { return 2; }
    return 0;
}
