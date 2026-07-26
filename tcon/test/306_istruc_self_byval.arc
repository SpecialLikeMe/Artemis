// PASS: istruc methods with `self: T` (by value) should work correctly:
// - by-value self receives a copy, mutations don't affect the original
// - by-pointer self (*T) mutations DO affect the original

istruc Point {
    let mut x: i32 = 0;
    let mut y: i32 = 0;

    // by-value self: gets a copy, mutations don't change the original
    fn sum_coords(self: Point) i32 {
        return self.x + self.y;
    }

    fn translate_copy(self: Point, dx: i32, dy: i32) Point {
        self.x = self.x + dx;
        self.y = self.y + dy;
        return self;
    }

    // by-pointer self: mutations DO change the original
    fn translate(self: *Point, dx: i32, dy: i32) void {
        self.x = self.x + dx;
        self.y = self.y + dy;
    }

    fn get_x(self: *Point) i32 { return self.x; }
    fn get_y(self: *Point) i32 { return self.y; }
}

pub fn main() i32 {
    let mut p: Point;
    p.x = 3;
    p.y = 4;

    // by-value: reads fields correctly
    if (p.sum_coords() != 7) { return 1; }

    // by-value copy doesn't change original
    let q: Point = p.translate_copy(10, 20);
    if (q.x != 13) { return 2; }
    if (q.y != 24) { return 3; }
    if (p.x != 3)  { return 4; }  // original unchanged
    if (p.y != 4)  { return 5; }

    // by-pointer mutates original
    p.translate(1, 2);
    if (p.get_x() != 4) { return 6; }
    if (p.get_y() != 6) { return 7; }

    return 0;
}
