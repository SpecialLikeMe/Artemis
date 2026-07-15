i32 main() {
    i32 r = 0;
    if comptime (1 < 2) { r = 1; } else { r = 2; }
    if (r != 1) { return 1; }
    comptime if (0) { return 5; } else { r = 3; }
    if (r != 3) { return 2; }
    return 0;
}
