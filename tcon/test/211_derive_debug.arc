// PASS: #[derive(Debug)] on an istruc synthesises __derive_Debug_Point.

#[derive(Debug)]
istruc Point {
    let mut x: i32;
    let mut y: i32;
}

pub fn main() i32 {
    let mut p: Point;
    p.x = 3;
    p.y = 4;
    __derive_Debug_Point(&p);
    return 0;
}
