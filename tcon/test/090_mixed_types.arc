i32 main() {
    i32 i = 10;
    f64 f = (f64)i;
    f = f / 3.0;
    i32 back = (i32)f;
    if (back != 3) { return 1; }

    i8  b = 127;
    i32 promoted = (i32)b;
    if (promoted != 127) { return 2; }
    return 0;
}
