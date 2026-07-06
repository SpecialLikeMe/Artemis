// Test functions with distinct names (overloading was removed; each fn has a unique name)
i32 square_i32(i32 x) { return x * x; }
i64 square_i64(i64 x) { return x * x; }

i32 describe_one(i32 x) { return 0; }
i32 describe_two(i32 x, i32 y) { return 1; }

i32 main() {
    i32 a = square_i32(5);
    if (a != 25) { return 1; }

    i64 b = square_i64((i64)7);
    if (b != 49) { return 2; }

    if (describe_one(1)    != 0) { return 3; }
    if (describe_two(1, 2) != 1) { return 4; }

    return 0;
}
