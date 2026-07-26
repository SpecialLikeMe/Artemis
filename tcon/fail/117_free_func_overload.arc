// FAIL: free function overloading is not supported
fn compute(a: i32) i32 { return a; }
fn compute(a: i32, b: i32) i32 { return a + b; }  // must error: same name, different sig

fn main() i32 { return compute(1); }
