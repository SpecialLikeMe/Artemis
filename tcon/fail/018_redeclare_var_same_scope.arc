// FAIL: redeclaring the same variable in the same scope
i32 main() {
    i32 x = 1;
    i32 x = 2;  // ERROR: redeclaration
    return x;
}
