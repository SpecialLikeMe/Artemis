// Test: namespace istruc — static methods, intra-namespace type in method return
namespace shapes {
    struct Vec2 { let x: f64; let y: f64; }

    istruc Circle {
        let mut center: Vec2;
        let mut radius: f64;

        fn __construct__(self: *Circle, cx: f64, cy: f64, r: f64) void {
            self.center.x = cx;
            self.center.y = cy;
            self.radius   = r;
        }

        // Intra-namespace: Vec2 unqualified, calls make_vec2 unqualified
        fn get_center(self: *const Circle) Vec2 { return self.center; }

        static fn unit() Circle {
            let mut c: Circle;
            c.center.x = 0.0; c.center.y = 0.0; c.radius = 1.0;
            return c;
        }
    }
}

pub fn main() i32 {
    let mut c: shapes.Circle(1.0, 2.0, 3.0);
    let mut v: shapes.Vec2= c.get_center();
    if (v.x != 1.0) { return 1; }
    if (v.y != 2.0) { return 2; }

    // verify radius field
    if (c.radius != 3.0) { return 3; }

    return 0;
}
