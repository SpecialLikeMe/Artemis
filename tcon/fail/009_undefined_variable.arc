// FAIL: using an undeclared variable must be rejected
fn main() i32 {
    let mut y: i32= x + 1;  // ERROR: 'x' undeclared
    return y;
}
