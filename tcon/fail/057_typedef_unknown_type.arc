// FAIL: using referencing an undeclared type
using Alias = Phantom;  // ERROR: Phantom undeclared
fn main() i32 { return 0; }
