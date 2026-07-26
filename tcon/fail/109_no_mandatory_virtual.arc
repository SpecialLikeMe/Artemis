// mandatory virtual: derived MUST implement; base has a fallback body
istruc Shape {
    mandatory virtual i32 area(const Shape* self) { return 0; }
}

istruc Rect : Shape {
    let mut w: i32;
    let mut h: i32;
    fn __construct__(self: *Rect, pw: i32, ph: i32) void { self.w = pw; self.h = ph; }
    fn area(self: *const Rect) i32 override { return self.w * self.h; }
}

istruc Circle : Shape {
    let mut r: i32;
    fn __construct__(self: *Circle, radius: i32) void { self.r = radius; }
    fn area(self: *const Circle) i32 override { return self.r * self.r; }
}

fn main() i32 {
    fn rect(3, 4) Rect;
    if (rect.area() != 12) { return 1; }

    fn circ(5) Circle;
    if (circ.area() != 25) { return 2; }
    return 0;
}
