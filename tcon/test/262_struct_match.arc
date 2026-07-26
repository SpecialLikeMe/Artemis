// PASS: struct field destructuring in match patterns
struct Point {
    let x: i32;
    let y: i32;
}

pub fn main() i32 {
    let mut p: Point;
    p.x = 3;
    p.y = 7;

    let mut result: i32= 0;
    match(p) {
        .{ x: 3, y: 7 } => { result = 1; }
        _ => { result = 2; }
    }
    if (result != 1) { return 1; }

    return 0;
}
