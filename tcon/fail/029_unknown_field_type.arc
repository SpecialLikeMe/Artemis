// FAIL: struct field uses an undeclared type
struct Broken { Phantom x; }  // ERROR: Phantom undeclared
i32 main() { return 0; }
