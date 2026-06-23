i32 main() {
    i32 x = 42;
    i32* p = &x;
    if (*p != 42) { return 1; }
    *p = 99;
    if (x != 99)  { return 2; }
    return 0;
}
