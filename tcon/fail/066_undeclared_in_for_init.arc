// FAIL: undeclared identifier used in for-loop initializer
fn main() i32 {
    for (let mut i: i32 = nope; i < 10; i = i + 1) {}  // ERROR: nope undeclared
    return 0;
}
