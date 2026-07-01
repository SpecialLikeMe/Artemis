istruc Vec2 {
    i32 x;
    i32 y;

    void __construct__(&self, i32 a, i32 b) {
        self.x = a;
        self.y = b;
    }

    Vec2 operator+(&const self, Vec2 other) {
        Vec2 result;
        result.x = self.x + other.x;
        result.y = self.y + other.y;
        return result;
    }

    bool operator==(&const self, Vec2 other) {
        return self.x == other.x && self.y == other.y;
    }

    i32 dot(&const self, Vec2 other) {
        return self.x * other.x + self.y * other.y;
    }
}

i32 main() {
    Vec2 a(1, 2);
    Vec2 b(3, 4);

    Vec2 c = a + b;
    if (c.x != 4) { return 1; }
    if (c.y != 6) { return 2; }

    if (!(a == a))  { return 3; }
    if (a == b)     { return 4; }

    if (a.dot(b) != 11) { return 5; }

    return 0;
}
