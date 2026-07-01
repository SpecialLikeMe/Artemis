// mandatory virtual: derived MUST implement; base has a fallback body
istruc Shape {
    mandatory virtual i32 area(const Shape* self) { return 0; }
}

istruc Rect : Shape {
    i32 w;
    i32 h;
    void __construct__(Rect* self, i32 pw, i32 ph) { self.w = pw; self.h = ph; }
    i32 area(const Rect* self) override { return self.w * self.h; }
}

istruc Circle : Shape {
    i32 r;
    void __construct__(Circle* self, i32 radius) { self.r = radius; }
    i32 area(const Circle* self) override { return self.r * self.r; }
}

i32 main() {
    Rect rect(3, 4);
    if (rect.area() != 12) { return 1; }

    Circle circ(5);
    if (circ.area() != 25) { return 2; }
    return 0;
}
