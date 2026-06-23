i32 main() {
    i32 a = 1;
    i32 b = 1;
    if (!(a && b)) { return 1; }
    i32 c = 0;
    if (a && c)    { return 2; }
    if (c && a)    { return 3; }
    return 0;
}
