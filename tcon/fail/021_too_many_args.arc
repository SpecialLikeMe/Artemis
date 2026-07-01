// FAIL: too many arguments to a function call
i32 square(i32 x) { return x * x; }
i32 main() { return square(2, 3); }  // ERROR: expected 1, got 2
