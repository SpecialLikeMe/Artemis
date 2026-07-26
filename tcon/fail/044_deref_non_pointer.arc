// FAIL: dereferencing a non-pointer variable
fn main() i32 {
    let mut x: i32= 5;
    let mut y: i32= *x;  // ERROR: x is not a pointer
    return y;
}
