// FAIL: undeclared identifier in expression
i32 main() { return ghost_var + 1; }  // ERROR: ghost_var undeclared
