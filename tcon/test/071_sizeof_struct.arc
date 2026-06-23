struct Two { i32 a; i32 b; }
struct One { i8 x; }

i32 main() {
    if (sizeof(One) < 1) { return 1; }
    if (sizeof(Two) < 8) { return 2; }
    if (sizeof(Two) < sizeof(One)) { return 3; }
    return 0;
}
