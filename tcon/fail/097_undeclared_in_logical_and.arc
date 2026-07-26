// FAIL: undeclared identifier in logical-and expression
fn main() i32 {
    let mut x: i32= 1;
    if (x > 0 && missing_flag) { return 1; }  // ERROR: missing_flag undeclared
    return 0;
}
