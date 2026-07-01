// inline and register storage class keywords
inline i32 square(i32 x) { return x * x; }
inline i32 cube(i32 x)   { return x * x * x; }

i32 main() {
    register i32 a = 4;
    register i32 b = 3;

    if (square(a) != 16) { return 1; }
    if (cube(b)   != 27) { return 2; }

    register i32 c = square(a) + cube(b);
    if (c != 43) { return 3; }
    return 0;
}
