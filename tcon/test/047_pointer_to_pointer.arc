i32 main() {
    i32 x = 55;
    i32* p = &x;
    i32** pp = &p;
    if (**pp != 55)  { return 1; }
    **pp = 77;
    if (x != 77)     { return 2; }
    if (*p != 77)    { return 3; }
    return 0;
}
