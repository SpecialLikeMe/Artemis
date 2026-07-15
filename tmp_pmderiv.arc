tokenstream* add_clone(&memstr alloc, tokenstream* input) derive {
    return input;
}

#derive[add_clone]
istruc Point {
    i32 x;
    i32 y;
    void __construct__(Point* self, i32 x, i32 y) {
        self.x = x;
        self.y = y;
    }
}

i32 main() {
    Point p(3, 4);
    if (p.x != 3) { return 1; }
    if (p.y != 4) { return 2; }
    return 0;
}
