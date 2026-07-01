// FAIL: undeclared identifier used in for-loop initializer
i32 main() {
    for (i32 i = nope; i < 10; i = i + 1) {}  // ERROR: nope undeclared
    return 0;
}
