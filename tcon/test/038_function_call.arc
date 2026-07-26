fn square(x: i32) i32 { return x * x; }
fn cube(x: i32) i32   { return x * square(x); }

pub fn main() i32 {
    if (square(7)  != 49)  { return 1; }
    if (cube(3)    != 27)  { return 2; }
    if (square(square(2)) != 16) { return 3; }
    return 0;
}
