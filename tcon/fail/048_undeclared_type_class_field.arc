// FAIL: istruc field uses an undeclared type
istruc Container { Unknown item; }  // ERROR: Unknown undeclared
i32 main() { return 0; }
