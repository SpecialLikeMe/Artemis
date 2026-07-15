// Interface as parameter type — dispatch via explicit cast
interface Shape {
    i32 area(Shape* self);
}

istruc Rect : Shape {
    i32 w;
    i32 h;
    void __construct__(Rect* self, i32 w, i32 h) { self.w = w; self.h = h; }
    i32 area(Rect* self) { return self.w * self.h; }
}

istruc Circle : Shape {
    i32 r;
    void __construct__(Circle* self, i32 r) { self.r = r; }
    i32 area(Circle* self) { return self.r * self.r; }
}

i32 get_rect_area(interface Shape* s) {
    Rect* r = (Rect*)s;
    return r.area();
}

i32 get_circle_area(interface Shape* s) {
    Circle* c = (Circle*)s;
    return c.area();
}

i32 main() {
    Rect r(4, 5);
    Circle c(3);
    if (get_rect_area((void*)&r) != 20) { return 1; }
    if (get_circle_area((void*)&c) != 9) { return 2; }
    return 0;
}
