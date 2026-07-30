istruc Point {
    let mut x: i32;
    let mut y: i32;
    fn __construct__(self: *Point, a: i32, b: i32) void { self.x = a; self.y = b; }
    fn sum(self: *const Point) i32 { return self.x + self.y; }
}
pub fn main() i32 {
    let mut p: Point(3, 4);
    if (p.sum() != 7) { return 3; }
    return 0;
}
