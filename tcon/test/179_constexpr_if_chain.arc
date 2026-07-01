// constexpr if / if constexpr chains with else if
i32 main() {
    i32 r = 0;

    // if constexpr with else
    if constexpr (1 == 1) { r = r + 1; } else { r = r + 100; }
    if (r != 1) { return 1; }

    // constexpr if with else if chain
    constexpr if (0) {
        r = 999;
    } else if constexpr (1) {
        r = r + 10;
    } else {
        r = 999;
    }
    if (r != 11) { return 2; }

    // Nested constexpr variables
    constexpr i32 A = 3;
    constexpr i32 B = A * 2;
    constexpr i32 C = A + B;
    if (C != 9) { return 3; }
    return 0;
}
