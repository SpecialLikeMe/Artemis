// PASS: anytype parameter is lowered to opaque ptr, enabling generic-style functions.
pub fn double_int(foo: anytype) i32 {
    return (i32)foo * 2;
}

pub fn negate(x: anytype) i64 {
    return -(i64)x;
}

pub fn main() i32 {
    if (double_int(21) != 42) { return 1; }
    if (double_int((i32)5) != 10) { return 2; }
    if (negate((i64)7) != (i64)-7) { return 3; }
    return 0;
}
