// FAIL: calling __construct__ on a primitive variable
fn main() i32 {
    let mut x: i32= 5;
    x.__construct__(10);  // ERROR: x is i32, not a class instance
    return x;
}
