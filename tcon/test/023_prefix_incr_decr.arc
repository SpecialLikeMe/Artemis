i32 main() {
    i32 x = 5;
    i32 y = ++x;
    if (x != 6) { return 1; }
    if (y != 6) { return 2; }
    i32 z = --x;
    if (x != 5) { return 3; }
    if (z != 5) { return 4; }
    return 0;
}
