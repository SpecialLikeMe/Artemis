// FAIL: redeclaring a parameter name inside the function body
i32 foo(i32 x) {
    i32 x = x + 1;  // ERROR: redeclaration of 'x'
    return x;
}
i32 main() { return foo(0); }
