istruc Vec2 {
    let mut x: i32;
    let mut y: i32;

    fn __construct__(self: *Vec2, a: i32, b: i32) void {
        self.x = a;
        self.y = b;
    }

    fn operator+(self: *const Vec2, other: Vec2) Vec2 {
        let mut result: Vec2;
        result.x = self.x + other.x;
        result.y = self.y + other.y;
        return result;
    }

    fn operator==(self: *const Vec2, other: Vec2) bool {
        return self.x == other.x && self.y == other.y;
    }

    fn dot(self: *const Vec2, other: Vec2) i32 {
        return self.x * other.x + self.y * other.y;
    }
}

pub fn main() i32 {
    let mut a: Vec2(1, 2);
    let mut b: Vec2(3, 4);

    let mut c: Vec2= a + b;
    if (c.x != 4) { return 1; }
    if (c.y != 6) { return 2; }

    if (!(a == a))  { return 3; }
    if (a == b)     { return 4; }

    if (a.dot(b) != 11) { return 5; }

    return 0;
}
