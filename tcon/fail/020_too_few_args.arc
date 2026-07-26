// FAIL: too few arguments to a function call
fn add(a: i32, b: i32) i32 { return a + b; }
fn main() i32 { return add(1); }  // ERROR: expected 2 args, got 1
