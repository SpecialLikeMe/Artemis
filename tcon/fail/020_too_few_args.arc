// FAIL: too few arguments to a function call
i32 add(i32 a, i32 b) { return a + b; }
i32 main() { return add(1); }  // ERROR: expected 2 args, got 1
