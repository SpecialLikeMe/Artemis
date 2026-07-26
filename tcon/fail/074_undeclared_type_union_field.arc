// FAIL: union field uses an undeclared type
union Bad { let i: i32; let g: Ghost; }  // ERROR: Ghost undeclared
fn main() i32 { return 0; }
