// FAIL: function parameter uses an undeclared type
i32 bar(Qux x) { return 0; }  // ERROR: Qux undeclared
i32 main() { return 0; }
