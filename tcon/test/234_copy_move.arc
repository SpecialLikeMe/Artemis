// Test @shcopy, @decopy, @move operators
// PASS PASS PASS PASS PASS PASS
@unsafe extern fn puts(s: *i8) int;

istruc Vec2 {
    let mut x: int;
    let mut y: int;
}

pub @unsafe fn main() int {
    let mut a: Vec2;
    a.x = 3; a.y = 4;

    // @shcopy — explicit shallow copy (same as plain assignment)
    let mut b: Vec2= @shcopy(a);
    if (b.x == 3 && b.y == 4) { puts("PASS"); } else { puts("FAIL shcopy values"); }
    b.x = 99;
    if (a.x == 3) { puts("PASS"); } else { puts("FAIL shcopy independence"); }

    // @decopy — deep copy (falls back to shallow for structs without __deep_copy__)
    let mut c: Vec2= @decopy(a);
    if (c.x == 3 && c.y == 4) { puts("PASS"); } else { puts("FAIL decopy values"); }
    c.x = 55;
    if (a.x == 3) { puts("PASS"); } else { puts("FAIL decopy independence"); }

    // @move — copy value then zero source
    let mut d: Vec2;
    d.x = 10; d.y = 20;
    let mut e: Vec2= @move(d);
    if (e.x == 10 && e.y == 20) { puts("PASS"); } else { puts("FAIL move values"); }
    if (d.x == 0 && d.y == 0)   { puts("PASS"); } else { puts("FAIL move zeroed"); }

    return 0;
}
