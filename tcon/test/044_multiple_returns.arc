i32 abs_val(i32 x) {
    if (x < 0) { return -x; }
    return x;
}

i32 sign(i32 x) {
    if (x < 0)  { return -1; }
    if (x > 0)  { return 1; }
    return 0;
}

i32 main() {
    if (abs_val(-7)  != 7)  { return 1; }
    if (abs_val(7)   != 7)  { return 2; }
    if (sign(-5)     != -1) { return 3; }
    if (sign(5)      != 1)  { return 4; }
    if (sign(0)      != 0)  { return 5; }
    return 0;
}
