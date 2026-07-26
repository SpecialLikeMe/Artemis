// Test anonymous istruc per-instance init: `istruc { ... } x;`
// PASS PASS PASS PASS
fn puts(s: *i8) int;

pub fn main() int {
    istruc { let mut v: int; } x;
    x.v = 42;
    if (x.v == 42) { puts("PASS"); } else { puts("FAIL v"); }

    istruc { let mut a: int; let mut b: int; } pt;
    pt.a = 10;
    pt.b = 20;
    if (pt.a == 10) { puts("PASS"); } else { puts("FAIL a"); }
    if (pt.b == 20) { puts("PASS"); } else { puts("FAIL b"); }

    // Multiple anon istrucs in same scope
    istruc { let mut x: int; } s1;
    istruc { let mut x: int; } s2;
    s1.x = 100;
    s2.x = 200;
    if (s1.x == 100 && s2.x == 200) { puts("PASS"); } else { puts("FAIL multi"); }

    return 0;
}
