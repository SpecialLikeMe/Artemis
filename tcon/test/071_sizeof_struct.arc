struct Two { let a: i32; let b: i32; }
struct One { let x: i8; }

pub fn main() i32 {
    if (sizeof(One) < 1) { return 1; }
    if (sizeof(Two) < 8) { return 2; }
    if (sizeof(Two) < sizeof(One)) { return 3; }
    return 0;
}
