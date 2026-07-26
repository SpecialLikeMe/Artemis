// FAIL: accessing a non-existent member of a class must be rejected
istruc Point {
    let mut x: i32;
    let mut y: i32;
}

fn main() i32 {
    let mut p: Point;
    p.x = 1;
    let mut z: i32= p.z;  // ERROR: 'z' does not exist in Point
    return z;
}
