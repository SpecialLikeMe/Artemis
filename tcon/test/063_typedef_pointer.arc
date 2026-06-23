typedef i32* IntPtr;

void zero(IntPtr p) { *p = 0; }

i32 main() {
    i32 x = 55;
    IntPtr p = &x;
    if (*p != 55) { return 1; }
    zero(p);
    if (x != 0)   { return 2; }
    return 0;
}
