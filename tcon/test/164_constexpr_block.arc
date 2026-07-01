// constexpr {} block: code runs at compile time
i32 g = 0;

i32 main() {
    constexpr i32 N = 5;
    constexpr {
        i32 doubled = N * 2;
        g = doubled;
    }
    if (g != 10) { return 1; }

    constexpr i32 M = N + N;
    if (M != 10) { return 2; }
    return 0;
}
