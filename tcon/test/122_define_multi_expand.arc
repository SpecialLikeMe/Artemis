@define <ZERO> <0>

i32 main() {
    i32 a = ZERO;
    i32 b = ZERO;
    i32 c = ZERO;
    if (a != 0) { return 1; }
    if (b != 0) { return 2; }
    if (c != 0) { return 3; }
    if (a + b + c != 0) { return 4; }
    return 0;
}
