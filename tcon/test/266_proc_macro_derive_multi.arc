// PASS: multiple derive proc macros on the same istruc.
// Each macro injects a function that USES the decorated istruc's fields,
// proving injected code is integrated with the decorated type.

fn add_clone(&memstr alloc, tokenstream* input) *tokenstream derive {
    return quote {
        fn clone_point(src: *Point) Point {
            let mut dst: Point;
            dst.x = src.x;
            dst.y = src.y;
            return dst;
        }
    };
}

fn add_eq(&memstr alloc, tokenstream* input) *tokenstream derive {
    return quote {
        fn points_equal(a: *const Point, b: *const Point) bool {
            return a.x == b.x && a.y == b.y;
        }
    };
}

fn add_hash(&memstr alloc, tokenstream* input) *tokenstream derive {
    return quote {
        fn hash_point(p: *const Point) i32 {
            return p.x * 31 + p.y;
        }
    };
}

#derive[add_clone]
#derive[add_eq]
#derive[add_hash]
istruc Point {
    let mut x: i32;
    let mut y: i32;
    fn __construct__(self: *Point, x: i32, y: i32) void {
        self.x = x;
        self.y = y;
    }
    fn sum(self: *Point) i32 { return self.x + self.y; }
}

pub fn main() i32 {
    let mut p: Point(3, 4);
    if (p.sum() != 7) { return 1; }
    let mut q: Point(10, 20);
    if (q.sum() != 30) { return 2; }
    // Verify derive macros injected wrappers that USE the struct fields
    let mut p2: Point = clone_point(&p);
    if (p2.x != 3 || p2.y != 4) { return 3; }
    if (!points_equal(&p, &p2)) { return 4; }
    if (hash_point(&p) != 3 * 31 + 4) { return 5; }
    return 0;
}
