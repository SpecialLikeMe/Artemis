// FAIL: istruc inherits from an undeclared type
istruc Child : Ghost { i32 v; }  // ERROR: Ghost undeclared
i32 main() { return 0; }
