i32 main() {
    i32 a = 0;
    i32 b = 1;
    if (!(a || b)) { return 1; }
    if (!(b || a)) { return 2; }
    i32 c = 0;
    if (a || c)    { return 3; }
    return 0;
}
