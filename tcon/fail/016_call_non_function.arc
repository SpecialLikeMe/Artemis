// FAIL: calling a variable that is not a function
i32 main() {
    i32 x = 5;
    x(3);  // ERROR: x is not callable
    return 0;
}
