// FAIL: redefining a struct
struct Node { i32 v; }
struct Node { i32 v; i32 next; }  // ERROR: redeclaration
i32 main() { return 0; }
