// FAIL: redefining a struct
struct Node { let v: i32; }
struct Node { let v: i32; let next: i32; }  // ERROR: redeclaration
fn main() i32 { return 0; }
