i32 add(i32 a, i32 b) { return a + b; }
i32 mul(i32 a, i32 b) { return a * b; }

i32 apply_twice(i32(i32, i32)* op, i32 x, i32 y) {
    return op(op(x, y), y);
}

i32 dispatch(i32 choice, i32 a, i32 b) {
    i32(i32, i32)* op;
    if (choice == 0) {
        op = &add;
    } else {
        op = &mul;
    }
    return op(a, b);
}

i32 main() {
    i32(i32, i32)* f = &add;
    if (f(2, 3)  != 5)  { return 1; }

    f = &mul;
    if (f(2, 3)  != 6)  { return 2; }

    if (apply_twice(&add, 1, 2) != 5)  { return 3; }
    if (apply_twice(&mul, 2, 3) != 18) { return 4; }

    if (dispatch(0, 10, 5) != 15) { return 5; }
    if (dispatch(1, 10, 5) != 50) { return 6; }

    return 0;
}
