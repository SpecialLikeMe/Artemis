// PASS: @shcopy and @move semantics on structs.
struct Point { let x: i32; let y: i32; }
pub fn main() i32 {
    let mut a: Point;
    a.x = 3; a.y = 4;

    // @shcopy: shallow copy, independent value
    let mut b: Point= @shcopy(a);
    if (b.x != 3 || b.y != 4) { return 1; }
    b.x = 99;
    if (a.x != 3) { return 2; }  // original unchanged

    // @move: transfers value and zeros source
    let mut c: Point= @move(a);
    if (c.x != 3 || c.y != 4) { return 3; }
    if (a.x != 0 || a.y != 0) { return 4; }  // source zeroed

    return 0;
}
