// PASS: interface method dispatch through fat-pointer vtable
interface Drawable {
    fn draw(self: *Drawable) i32;
    fn area(self: *Drawable) i32;
}

istruc Circle : Drawable {
    let mut r: i32;
    fn __construct__(self: *Circle, r: i32) void { self.r = r; }
    fn draw(self: *Circle) i32 { return self.r * 2; }
    fn area(self: *Circle) i32 { return self.r * self.r; }
}

istruc Square : Drawable {
    let mut s: i32;
    fn __construct__(self: *Square, s: i32) void { self.s = s; }
    fn draw(self: *Square) i32 { return self.s * 4; }
    fn area(self: *Square) i32 { return self.s * self.s; }
}

fn do_draw(d: Drawable) i32 { return d.draw(); }
fn do_area(d: Drawable) i32 { return d.area(); }

pub fn main() i32 {
    let mut c: Circle(5);
    let mut sq: Square(4);
    if (do_draw(c)  != 10) { return 1; }
    if (do_draw(sq) != 16) { return 2; }
    if (do_area(c)  != 25) { return 3; }
    if (do_area(sq) != 16) { return 4; }
    return 0;
}
