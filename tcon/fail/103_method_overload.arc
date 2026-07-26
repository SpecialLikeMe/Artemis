// Method overloading is not supported in Artemis.
// Two methods with the same name on an istruc must be an error.
istruc Vec2 {
    let mut x: i32;
    let mut y: i32;

    fn __construct__(self: *Vec2, v: i32) void {
        self.x = v;
        self.y = v;
    }

    fn __construct__(self: *Vec2, px: i32, py: i32) void {
        self.x = px;
        self.y = py;
    }
}

fn main() i32 {
    fn a(5) Vec2;
    return 0;
}
