// Namespace: deprecated :: still works (produces deprecation warning, same result)
// Also tests multiple namespaces and passing namespace results to functions.
namespace Vec2 {
    i32 dot(i32 ax, i32 ay, i32 bx, i32 by) { return ax * bx + ay * by; }
    i32 len_sq(i32 x, i32 y)                { return x * x + y * y; }
}

namespace Utils {
    i32 clamp(i32 v, i32 lo, i32 hi) {
        if (v < lo) { return lo; }
        if (v > hi) { return hi; }
        return v;
    }
    bool in_range(i32 v, i32 lo, i32 hi) { return v >= lo && v <= hi; }
}

i32 main() {
    if (Vec2.dot(1, 0, 0, 1) != 0)       { return 1; }
    if (Vec2.dot(3, 4, 3, 4) != 25)      { return 2; }
    if (Vec2.len_sq(3, 4) != 25)         { return 3; }

    if (Utils.clamp(5, 0, 10) != 5)      { return 4; }
    if (Utils.clamp(-5, 0, 10) != 0)     { return 5; }
    if (Utils.clamp(15, 0, 10) != 10)    { return 6; }
    if (!Utils.in_range(7, 1, 10))       { return 7; }
    if (Utils.in_range(11, 1, 10))       { return 8; }

    // Nest namespace calls
    i32 clamped = Utils.clamp(Vec2.dot(2, 3, 1, 1), 0, 100);
    if (clamped != 5)                    { return 9; }

    return 0;
}
