// FAIL: using an undeclared variable must be rejected
i32 main() {
    i32 y = x + 1;  // ERROR: 'x' undeclared
    return y;
}
