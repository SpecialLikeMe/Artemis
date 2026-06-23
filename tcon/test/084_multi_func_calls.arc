i32 add(i32 a, i32 b) { return a + b; }
i32 mul(i32 a, i32 b) { return a * b; }
i32 sub(i32 a, i32 b) { return a - b; }

i32 main() {
    i32 r = add(mul(2, 3), sub(10, 4));
    if (r != 12) { return 1; }
    i32 s = mul(add(1, 2), add(3, 4));
    if (s != 21) { return 2; }
    return 0;
}
