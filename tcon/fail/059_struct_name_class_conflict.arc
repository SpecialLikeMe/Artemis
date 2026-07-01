// FAIL: declaring both a struct and istruc with the same name
struct Conflict { i32 x; }
istruc Conflict { i32 y; }  // ERROR: redeclaration
i32 main() { return 0; }
