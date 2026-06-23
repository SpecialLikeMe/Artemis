i32 main() {
    u8 a = 2;
    if (a != 2) { return 1; }

    u8 b = 200;
    if (b != 200) { return 2; }

    i16 c = a;
    if (c != 2) { return 3; }

    i32 big = 42;
    u8 small = big;
    if (small != 42) { return 4; }

    u8 x = 0;
    x = 99;
    if (x != 99) { return 5; }

    return 0;
}
