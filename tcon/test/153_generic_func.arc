T identity<T>(T x) { return x; }
i32 main() {
    i32 a = identity<i32>(42);
    if (a != 42) { return 1; }
    return 0;
}
