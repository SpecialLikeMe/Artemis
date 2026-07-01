// FAIL: array of an undeclared element type
i32 main() {
    Phantom arr[5];  // ERROR: Phantom undeclared
    return 0;
}
