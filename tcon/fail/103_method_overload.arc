// Method overloading is not supported in Artemis.
// Two methods with the same name on an istruc must be an error.
istruc Vec2 {
    i32 x;
    i32 y;

    void __construct__(Vec2* self, i32 v) {
        self.x = v;
        self.y = v;
    }

    void __construct__(Vec2* self, i32 px, i32 py) {
        self.x = px;
        self.y = py;
    }
}

i32 main() {
    Vec2 a(5);
    return 0;
}
