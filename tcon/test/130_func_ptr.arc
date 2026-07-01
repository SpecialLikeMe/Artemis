i32 add(i32 a, i32 b) { return a + b; }
i32 mul(i32 a, i32 b) { return a * b; }
i32 sub(i32 a, i32 b) { return a - b; }

i32 apply(i32(i32, i32)* op, i32 x, i32 y) {
    return op(x, y);
}

i32 main() {
    i32(i32, i32)* op = &add;
    if (op(3, 4)   != 7)  { return 1; }

    op = &mul;
    if (op(3, 4)   != 12) { return 2; }

    op = &sub;
    if (op(10, 3)  != 7)  { return 3; }

    if (apply(&add, 5, 6) != 11) { return 4; }
    if (apply(&mul, 5, 6) != 30) { return 5; }

    return 0;
}
