// FAIL: undeclared identifier in logical-and expression
i32 main() {
    i32 x = 1;
    if (x > 0 && missing_flag) { return 1; }  // ERROR: missing_flag undeclared
    return 0;
}
