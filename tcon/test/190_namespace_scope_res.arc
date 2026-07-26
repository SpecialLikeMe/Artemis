// Namespace access using '.' syntax.
// Also tests multiple namespaces and passing namespace results to functions.
namespace Vec2 {
    fn dot(ax: i32, ay: i32, bx: i32, by: i32) i32 { return ax * bx + ay * by; }
    fn len_sq(x: i32, y: i32) i32                { return x * x + y * y; }
}

namespace Utils {
    fn clamp(v: i32, lo: i32, hi: i32) i32 {
        if (v < lo) { return lo; }
        if (v > hi) { return hi; }
        return v;
    }
    fn in_range(v: i32, lo: i32, hi: i32) bool { return v >= lo && v <= hi; }
}

pub fn main() i32 {
    if (Vec2.dot(1, 0, 0, 1) != 0)       { return 1; }
    if (Vec2.dot(3, 4, 3, 4) != 25)      { return 2; }
    if (Vec2.len_sq(3, 4) != 25)         { return 3; }

    if (Utils.clamp(5, 0, 10) != 5)      { return 4; }
    if (Utils.clamp(-5, 0, 10) != 0)     { return 5; }
    if (Utils.clamp(15, 0, 10) != 10)    { return 6; }
    if (!Utils.in_range(7, 1, 10))       { return 7; }
    if (Utils.in_range(11, 1, 10))       { return 8; }

    // Nest namespace calls
    let mut clamped: i32= Utils.clamp(Vec2.dot(2, 3, 1, 1), 0, 100);
    if (clamped != 5)                    { return 9; }

    return 0;
}
