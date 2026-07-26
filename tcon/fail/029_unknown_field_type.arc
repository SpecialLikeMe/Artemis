// FAIL: struct field uses an undeclared type
struct Broken { let x: Phantom; }  // ERROR: Phantom undeclared
fn main() i32 { return 0; }
