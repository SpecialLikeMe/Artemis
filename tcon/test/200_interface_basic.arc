// Test: basic interface declaration and implementation checking
@unsafe extern fn printf(fmt: *i8, ...) i32;

interface Describable {
    fn describe(self: *Describable) i32;
}

istruc Point : Describable {
    let mut x: i32;
    let mut y: i32;

    fn __construct__(self: *Point, px: i32, py: i32) void {
        self.x = px;
        self.y = py;
    }

    fn describe(self: *Point) i32 {
        return self.x * 100 + self.y;
    }
}

pub fn main() i32 {
    let mut p: Point(3, 7);
    if (p.describe() != 307) { return 1; }
    return 0;
}
