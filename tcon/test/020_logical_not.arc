i32 main() {
    i32 a = 0;
    if (!(!a)) { return 1; }
    i32 b = 5;
    if (!b)    { return 2; }
    if (!!a)   { return 3; }
    return 0;
}
