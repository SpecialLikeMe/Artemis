// FAIL: calling __construct__ on a primitive variable
i32 main() {
    i32 x = 5;
    x.__construct__(10);  // ERROR: x is i32, not a class instance
    return x;
}
