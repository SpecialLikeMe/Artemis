// FAIL: function parameter uses an undeclared type
fn bar(x: Qux) i32 { return 0; }  // ERROR: Qux undeclared
fn main() i32 { return 0; }
