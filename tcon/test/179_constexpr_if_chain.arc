// comptime if / if comptime chains with else if
i32 main() {
    i32 r = 0;

    // if comptime with else
    if comptime (1 == 1) { r = r + 1; } else { r = r + 100; }
    if (r != 1) { return 1; }

    // comptime if with else if chain
    comptime if (0) {
        r = 999;
    } else if comptime (1) {
        r = r + 10;
    } else {
        r = 999;
    }
    if (r != 11) { return 2; }

    // Nested comptime variables
    comptime i32 A = 3;
    comptime i32 B = A * 2;
    comptime i32 C = A + B;
    if (C != 9) { return 3; }
    return 0;
}
