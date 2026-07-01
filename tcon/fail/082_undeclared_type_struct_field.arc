// FAIL: struct field with an undeclared type (via typedef alias of unknown)
struct Bad { Undefined x; }  // ERROR: Undefined undeclared
i32 main() { return 0; }
