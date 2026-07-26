const MAX: i32 = 100;
const PI: f64  = 3.14159;

pub fn main() i32 {
    if (MAX != 100) { return 1; }
    let mut x: i32= MAX / 4;
    if (x != 25) { return 2; }
    let mut result: i32= 0;
    if (result > MAX) { return 3; }
    return 0;
}
