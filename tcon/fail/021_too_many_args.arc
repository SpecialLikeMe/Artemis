// FAIL: too many arguments to a function call
fn square(x: i32) i32 { return x * x; }
fn main() i32 { return square(2, 3); }  // ERROR: expected 1, got 2
