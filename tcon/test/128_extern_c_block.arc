extern "C" {
    i32 abs(i32 x);
    i64 llabs(i64 x);
}

i32 main() {
    if (abs(-9)   != 9)  { return 1; }
    if (abs(4)    != 4)  { return 2; }
    if (llabs((i64)-100) != (i64)100) { return 3; }
    return 0;
}
