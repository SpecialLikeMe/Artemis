// FAIL: calling a zero-argument function with arguments
fn get_zero() i32 { return 0; }
fn main() i32 { return get_zero(1, 2); }  // ERROR: expected 0 args, got 2
