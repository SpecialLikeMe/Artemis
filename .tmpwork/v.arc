istruc Point {
    let mut x: i32;
    fn __construct__(self: *Point, a: i32) void { self.x = a; }
    fn sum(self: *const Point) i32 { return self.x; }
    fn zzz(self: *Point) void { self.x = self.x; }
}
pub fn main() i32 { let mut p: Point; if (p.sum()!=0) { return 3; } return 0; }
