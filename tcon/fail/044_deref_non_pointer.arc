// FAIL: dereferencing a non-pointer variable
i32 main() {
    i32 x = 5;
    i32 y = *x;  // ERROR: x is not a pointer
    return y;
}
