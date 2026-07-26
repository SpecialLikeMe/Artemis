// Interface as parameter type — dispatch via explicit cast
interface Shape {
    fn area(self: *Shape) i32;
}

istruc Rect : Shape {
    let mut w: i32;
    let mut h: i32;
    fn __construct__(self: *Rect, w: i32, h: i32) void { self.w = w; self.h = h; }
    fn area(self: *Rect) i32 { return self.w * self.h; }
}

istruc Circle : Shape {
    let mut r: i32;
    fn __construct__(self: *Circle, r: i32) void { self.r = r; }
    fn area(self: *Circle) i32 { return self.r * self.r; }
}

fn get_rect_area(s: interface Shape*) i32 {
    let mut r: *Rect= (Rect*)s;
    return r.area();
}

fn get_circle_area(s: interface Shape*) i32 {
    let mut c: *Circle= (Circle*)s;
    return c.area();
}

pub fn main() i32 {
    let mut r: Rect(4, 5);
    let mut c: Circle(3);
    if (get_rect_area((void*)&r) != 20) { return 1; }
    if (get_circle_area((void*)&c) != 9) { return 2; }
    return 0;
}
