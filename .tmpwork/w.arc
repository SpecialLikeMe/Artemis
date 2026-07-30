istruc Point {
    let mut x: i32;
    fn sum(self: *const Point) i32 { return self.x; }
    fn zzz(self: *Point, f: i32) void { self.x = f; }
}
pub fn main() i32 { let mut p: Point; p.x=7; if (p.sum() != 7) { return 3; } return 0; }
