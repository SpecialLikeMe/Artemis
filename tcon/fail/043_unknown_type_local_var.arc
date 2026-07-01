// FAIL: local variable declaration uses an undeclared type name
i32 main() {
    Blarg x;  // ERROR: Blarg is undeclared
    return 0;
}
