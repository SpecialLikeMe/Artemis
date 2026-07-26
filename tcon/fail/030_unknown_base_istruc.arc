// FAIL: istruc inherits from an undeclared type
istruc Child : Ghost { let mut v: i32; }  // ERROR: Ghost undeclared
fn main() i32 { return 0; }
