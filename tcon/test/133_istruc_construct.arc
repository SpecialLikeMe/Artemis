istruc Point {
    let mut x: i32;
    let mut y: i32;

    fn __construct__(self: *Point, a: i32, b: i32) void {
        self.x = a;
        self.y = b;
    }

    fn sum(self: *const Point) i32 {
        return self.x + self.y;
    }

    fn scale(self: *Point, factor: i32) void {
        self.x = self.x * factor;
        self.y = self.y * factor;
    }
}

pub fn main() i32 {
    let mut p: Point(3, 4);
    if (p.x != 3)        { return 1; }
    if (p.y != 4)        { return 2; }
    if (p.sum() != 7)    { return 3; }

    p.scale(2);
    if (p.x != 6)        { return 4; }
    if (p.y != 8)        { return 5; }
    if (p.sum() != 14)   { return 6; }

    let mut q: Point(10, 20);
    if (q.sum() != 30)   { return 7; }
    if (p.sum() != 14)   { return 8; }

    return 0;
}
