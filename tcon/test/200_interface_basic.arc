// Test: basic interface declaration and implementation checking
extern i32 printf(i8* fmt, ...);

interface Describable {
    i32 describe(Describable* self);
}

istruc Point : Describable {
    i32 x;
    i32 y;

    void __construct__(Point* self, i32 px, i32 py) {
        self.x = px;
        self.y = py;
    }

    i32 describe(Point* self) {
        return self.x * 100 + self.y;
    }
}

i32 main() {
    Point p(3, 7);
    if (p.describe() != 307) { return 1; }
    return 0;
}
