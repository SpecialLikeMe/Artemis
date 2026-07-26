// FAIL: undeclared identifier on the right-hand side of an assignment
fn main() i32 {
    let mut x: i32= 0;
    x = ghost_value;  // ERROR: ghost_value undeclared
    return x;
}
