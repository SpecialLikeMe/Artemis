// FAIL: undeclared identifier in expression
fn main() i32 { return ghost_var + 1; }  // ERROR: ghost_var undeclared
