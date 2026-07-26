fn add3(a: i32, b: i32, c: i32) i32 { return a + b + c; }
fn max2(a: i32, b: i32) i32 { return a > b ? a : b; }

pub fn main() i32 {
    if (add3(1, 2, 3)   != 6)  { return 1; }
    if (add3(10, 20, 30) != 60){ return 2; }
    if (max2(7, 3)       != 7) { return 3; }
    if (max2(3, 7)       != 7) { return 4; }
    return 0;
}
