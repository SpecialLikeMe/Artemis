// FAIL: undeclared identifier in if condition
fn main() i32 {
    if (undefined_var) { return 1; }  // ERROR: undefined_var undeclared
    return 0;
}
