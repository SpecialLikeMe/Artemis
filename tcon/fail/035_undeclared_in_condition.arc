// FAIL: undeclared identifier in if condition
i32 main() {
    if (undefined_var) { return 1; }  // ERROR: undefined_var undeclared
    return 0;
}
