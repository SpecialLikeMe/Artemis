struct Point {
    let x: i32;
    let y: i32;
}

pub fn main() i32 {
    let mut p: Point;
    p.x = 3;
    p.y = 4;
    if (p.x != 3) { return 1; }
    if (p.y != 4) { return 2; }
    p.x = p.x + p.y;
    if (p.x != 7) { return 3; }
    return 0;
}
