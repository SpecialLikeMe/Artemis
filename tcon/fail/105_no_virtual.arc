istruc Shape {
    let mut id: i32;

    fn __construct__(self: *Shape, n: i32) void {
        self.id = n;
    }

    virtual i32 area(const Shape* self) {
        return 0;
    }

    fn get_id(self: *const Shape) i32 {
        return self.id;
    }
}

istruc Circle : Shape {
    let mut r: i32;

    fn __construct__(self: *Circle, n: i32, radius: i32) void {
        self.id = n;
        self.r = radius;
    }

    fn area(self: *const Circle) i32 override {
        return self.r * self.r;
    }
}

istruc Square : Shape {
    let mut side: i32;

    fn __construct__(self: *Square, n: i32, s: i32) void {
        self.id = n;
        self.side = s;
    }

    fn area(self: *const Square) i32 override {
        return self.side * self.side;
    }
}

fn main() i32 {
    fn s(0) Shape;
    if (s.area()   != 0)  { return 1; }
    if (s.get_id() != 0)  { return 2; }

    fn c(1, 5) Circle;
    if (c.area()   != 25) { return 3; }
    if (c.get_id() != 1)  { return 4; }
    if (c.r        != 5)  { return 5; }

    fn sq(2, 4) Square;
    if (sq.area()   != 16) { return 6; }
    if (sq.get_id() != 2)  { return 7; }

    return 0;
}
