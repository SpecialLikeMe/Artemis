// PASS: @shcopy, @decopy, @move, ref operator basics.
pub fn main() i32 {
    let mut a: i32= 42;

    // @shcopy: explicit shallow copy (same as assignment for primitives)
    let mut b: i32= @shcopy(a);
    if (b != 42) { return 1; }

    // @decopy: deep copy (same as shallow for primitives)
    let mut c: i32= @decopy(a);
    if (c != 42) { return 2; }

    // @move: copy value, zero source
    let mut d: i32= @move(a);
    if (d != 42)  { return 3; }
    if (a != 0)   { return 4; }

    // ref: build a pointer to a value
    let mut x: i32= 100;
    let mut p: *i32= ref x;
    if (*p != 100) { return 5; }
    *p = 200;
    if (x != 200)  { return 6; }

    return 0;
}
