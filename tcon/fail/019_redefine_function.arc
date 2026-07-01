// FAIL: redefining a function with two bodies sharing the same signature
i32 foo(i32 x) { return x; }
i32 foo(i32 x) { return x + 1; }  // ERROR: redefinition
i32 main() { return foo(0); }
