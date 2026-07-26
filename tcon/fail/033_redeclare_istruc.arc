// FAIL: redefining the same istruc
istruc Foo { let mut x: i32; }
istruc Foo { let mut y: i32; }  // ERROR: redeclaration
fn main() i32 { return 0; }
