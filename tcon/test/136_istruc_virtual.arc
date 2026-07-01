istruc Shape {
    i32 id;

    void __construct__(&self, i32 n) {
        self.id = n;
    }

    virtual i32 area(&const self) {
        return 0;
    }

    i32 get_id(&const self) {
        return self.id;
    }
}

istruc Circle : Shape {
    i32 r;

    void __construct__(&self, i32 n, i32 radius) {
        self.id = n;
        self.r = radius;
    }

    i32 area(&const self) override {
        return self.r * self.r;
    }
}

istruc Square : Shape {
    i32 side;

    void __construct__(&self, i32 n, i32 s) {
        self.id = n;
        self.side = s;
    }

    i32 area(&const self) override {
        return self.side * self.side;
    }
}

i32 main() {
    Shape s(0);
    if (s.area()   != 0)  { return 1; }
    if (s.get_id() != 0)  { return 2; }

    Circle c(1, 5);
    if (c.area()   != 25) { return 3; }
    if (c.get_id() != 1)  { return 4; }
    if (c.r        != 5)  { return 5; }

    Square sq(2, 4);
    if (sq.area()   != 16) { return 6; }
    if (sq.get_id() != 2)  { return 7; }

    return 0;
}
