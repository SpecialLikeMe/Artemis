// PASS: @cstype(@typeinfo(T)) is the inverse of @typeinfo — produces type T.
// Round-trip identity: @cstype(@typeinfo(T)) == T.

struct Point { let x: i32; let y: i32; }

pub fn main() i32 {
    // @cstype(@typeinfo(i32)) should be the same as i32
    let a: @cstype(@typeinfo(i32)) = 42;
    if (a != 42) { return 1; }

    // @cstype(@typeinfo(*i8)) should be the same as *i8
    let s: @cstype(@typeinfo(*i8)) = "hello";
    if (s[0] != 'h') { return 2; }

    // @cstype(@typeinfo(bool)) should be the same as bool
    let b: @cstype(@typeinfo(bool)) = true;
    if (!b) { return 3; }

    // @cstype(@typeinfo(f64)) should be the same as f64
    let f: @cstype(@typeinfo(f64)) = 3.14;
    if (f < 3.13 || f > 3.15) { return 4; }

    // @cstype(@typeinfo(Point)) should be a Point-compatible type
    let mut p: @cstype(@typeinfo(Point));
    p.x = 10;
    p.y = 20;
    if (p.x + p.y != 30) { return 5; }

    return 0;
}
