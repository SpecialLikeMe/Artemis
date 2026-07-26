// FAIL: calling a variable that is not a function
fn main() i32 {
    let mut x: i32= 5;
    x(3);  // ERROR: x is not callable
    return 0;
}
