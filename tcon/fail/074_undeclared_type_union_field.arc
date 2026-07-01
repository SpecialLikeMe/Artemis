// FAIL: union field uses an undeclared type
union Bad { i32 i; Ghost g; }  // ERROR: Ghost undeclared
i32 main() { return 0; }
