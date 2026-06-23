i32 square(i32 x) { return x * x; }
i32 cube(i32 x)   { return x * square(x); }

i32 main() {
    if (square(7)  != 49)  { return 1; }
    if (cube(3)    != 27)  { return 2; }
    if (square(square(2)) != 16) { return 3; }
    return 0;
}
