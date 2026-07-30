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
