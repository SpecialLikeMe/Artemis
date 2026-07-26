// FAIL: assigning to a non-mut let variable must be a compile error.
pub fn main() i32 {
    let x: i32 = 5;
    x = 10;
    return 0;
}
