// PASS: passing concrete istruc pointer where *Interface param is expected
// should auto-coerce to fat pointer { data_ptr, vtable_ptr }

interface Drawable {
    fn draw(self: *Drawable) i32;
}

interface Sizable {
    fn size(self: *Sizable) i32;
}

istruc Circle : Drawable, Sizable {
    let mut radius: i32 = 5;
    fn draw(self: *Circle) i32 { return self.radius * 2; }
    fn size(self: *Circle) i32 { return self.radius; }
}

istruc Square : Drawable, Sizable {
    let mut side: i32 = 3;
    fn draw(self: *Square) i32 { return self.side * self.side; }
    fn size(self: *Square) i32 { return self.side; }
}

fn render(d: *Drawable) i32 {
    return d.draw();
}

fn measure(s: *Sizable) i32 {
    return s.size();
}

fn render_and_measure(d: *Drawable, s: *Sizable) i32 {
    return d.draw() + s.size();
}

pub fn main() i32 {
    let mut c: Circle;
    let mut sq: Square;

    // Pass concrete pointer where interface pointer expected
    if (render(&c) != 10)        { return 1; }  // 5*2
    if (render(&sq) != 9)        { return 2; }  // 3*3
    if (measure(&c) != 5)        { return 3; }
    if (measure(&sq) != 3)       { return 4; }

    // Two different interface params
    if (render_and_measure(&c, &sq) != 13) { return 5; } // 10 + 3
    if (render_and_measure(&sq, &c) != 14) { return 6; } // 9 + 5

    return 0;
}
