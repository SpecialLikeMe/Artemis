i32 square(i32 x) { return x * x; }
i64 square(i64 x) { return x * x; }

i32 describe(i32 x) { return 0; }
i32 describe(i32 x, i32 y) { return 1; }

i32 main() {
    i32 a = square(5);
    if (a != 25) { return 1; }

    i64 b = square((i64)7);
    if (b != 49) { return 2; }

    if (describe(1)    != 0) { return 3; }
    if (describe(1, 2) != 1) { return 4; }

    return 0;
}
