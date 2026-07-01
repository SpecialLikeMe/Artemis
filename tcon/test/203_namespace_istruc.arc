// Test: namespace istruc — static methods, intra-namespace type in method return
namespace shapes {
    struct Vec2 { f64 x; f64 y; }

    istruc Circle {
        Vec2 center;
        f64  radius;

        void __construct__(Circle* self, f64 cx, f64 cy, f64 r) {
            self.center.x = cx;
            self.center.y = cy;
            self.radius   = r;
        }

        // Intra-namespace: Vec2 unqualified, calls make_vec2 unqualified
        Vec2 get_center(const Circle* self) { return self.center; }

        static Circle unit() {
            Circle c;
            c.center.x = 0.0; c.center.y = 0.0; c.radius = 1.0;
            return c;
        }
    }
}

i32 main() {
    shapes::Circle c(1.0, 2.0, 3.0);
    shapes::Vec2   v = c.get_center();
    if (v.x != 1.0) { return 1; }
    if (v.y != 2.0) { return 2; }

    // verify radius field
    if (c.radius != 3.0) { return 3; }

    return 0;
}
