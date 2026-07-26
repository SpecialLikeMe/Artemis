istruc Vec2 {
    let mut x: i32;
    let mut y: i32;
    fn sum(self: *const Vec2) i32 { return self.x + self.y; }
}
pub fn main() i32 {
    let mut v: Vec2= .{ .x = 1, .y = 2 };
    if (v.sum() != 3) { return 1; }
    return 0;
}
