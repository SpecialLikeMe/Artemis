// FAIL: redefining the same istruc
istruc Foo { i32 x; }
istruc Foo { i32 y; }  // ERROR: redeclaration
i32 main() { return 0; }
