istruc Point {
    i32 x;
    i32 y;
    void __construct__(&self, i32 a, i32 b) { self.x = a; self.y = b; }
    i32 sum(&const self) { return self.x + self.y; }
}
i32 main() {
    Point p(3, 4);
    if (p.sum() != 7) { return 1; }
    Point q{10, 20};
    if (q.sum() != 30) { return 2; }
    return 0;
}
