// FAIL: declaring both a struct and istruc with the same name
struct Conflict { let x: i32; }
istruc Conflict { let mut y: i32; }  // ERROR: redeclaration
fn main() i32 { return 0; }
