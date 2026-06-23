i32 main() {
    f64 f = 9.99;
    i32 i = (i32)f;
    if (i != 9) { return 1; }
    f64 g = -3.7;
    i32 j = (i32)g;
    if (j != -3) { return 2; }
    return 0;
}
