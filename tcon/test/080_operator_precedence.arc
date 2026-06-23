i32 main() {
    i32 r1 = 2 + 3 * 4;
    if (r1 != 14) { return 1; }

    i32 r2 = (2 + 3) * 4;
    if (r2 != 20) { return 2; }

    i32 r3 = 10 - 3 - 2;
    if (r3 != 5)  { return 3; }

    i32 r4 = 8 / 2 * 4;
    if (r4 != 16) { return 4; }

    i32 r5 = 1 + 2 == 3;
    if (r5 != 1)  { return 5; }

    i32 r6 = 0 || 1 && 0;
    if (r6 != 0)  { return 6; }
    return 0;
}
