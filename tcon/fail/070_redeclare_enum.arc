// FAIL: redefining an enum
enum Color { Red, Green, Blue }
enum Color { Red, Green }  // ERROR: redeclaration
i32 main() { return 0; }
