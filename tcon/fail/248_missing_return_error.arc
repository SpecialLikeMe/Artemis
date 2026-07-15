// FAIL: non-void function with no return statement must be rejected
i32 foo() {
    i32 x = 5;
    // no return
}
i32 main() { return foo(); }
