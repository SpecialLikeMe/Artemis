// FAIL: struct field with an undeclared type (via using alias of unknown)
struct Bad { let x: Undefined; }  // ERROR: Undefined undeclared
fn main() i32 { return 0; }
