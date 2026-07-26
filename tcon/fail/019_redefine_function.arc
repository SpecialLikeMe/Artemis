// FAIL: redefining a function with two bodies sharing the same signature
fn foo(x: i32) i32 { return x; }
fn foo(x: i32) i32 { return x + 1; }  // ERROR: redefinition
fn main() i32 { return foo(0); }
