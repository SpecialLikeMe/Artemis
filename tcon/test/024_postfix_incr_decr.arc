i32 main() {
    i32 x = 5;
    i32 y = x++;
    if (y != 5) { return 1; }
    if (x != 6) { return 2; }
    i32 z = x--;
    if (z != 6) { return 3; }
    if (x != 5) { return 4; }
    return 0;
}
