// FAIL: calling a zero-argument function with arguments
i32 get_zero() { return 0; }
i32 main() { return get_zero(1, 2); }  // ERROR: expected 0 args, got 2
