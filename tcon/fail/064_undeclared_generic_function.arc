// FAIL: calling a generic function that does not exist
fn main() i32 {
    let mut x: i32= no_such_generic<i32>(5);  // ERROR: undeclared
    return x;
}
