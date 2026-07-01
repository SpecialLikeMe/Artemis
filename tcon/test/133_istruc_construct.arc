istruc Point {
    i32 x;
    i32 y;

    void __construct__(Point* self, i32 a, i32 b) {
        self.x = a;
        self.y = b;
    }

    i32 sum(const Point* self) {
        return self.x + self.y;
    }

    void scale(Point* self, i32 factor) {
        self.x = self.x * factor;
        self.y = self.y * factor;
    }
}

i32 main() {
    Point p(3, 4);
    if (p.x != 3)        { return 1; }
    if (p.y != 4)        { return 2; }
    if (p.sum() != 7)    { return 3; }

    p.scale(2);
    if (p.x != 6)        { return 4; }
    if (p.y != 8)        { return 5; }
    if (p.sum() != 14)   { return 6; }

    Point q(10, 20);
    if (q.sum() != 30)   { return 7; }
    if (p.sum() != 14)   { return 8; }

    return 0;
}
