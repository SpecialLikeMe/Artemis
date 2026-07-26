// FAIL: local variable declaration uses an undeclared type name
fn main() i32 {
    let mut x: Blarg;  // ERROR: Blarg is undeclared
    return 0;
}
