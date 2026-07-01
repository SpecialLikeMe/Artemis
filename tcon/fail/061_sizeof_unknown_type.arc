// FAIL: sizeof applied to an undeclared type
i32 main() {
    i32 s = sizeof(Imaginary);  // ERROR: Imaginary undeclared
    return s;
}
