// Per-instance istruc init: `istruc { ... } x;`
// Tests anonymous istruc with a constructor and methods
istruc {
    let mut value: i32;
    fn __construct__(v: i32) void { self.value = v; }
    fn get() i32 { return self.value; }
    fn set(v: i32) void { self.value = v; }
} obj;

pub fn main() i32 {
    istruc { let mut x: i32; let mut y: i32; } pt;
    pt.x = 3;
    pt.y = 4;
    if (pt.x != 3) { return 1; }
    if (pt.y != 4) { return 2; }

    istruc { let mut a: i32; } s1;
    istruc { let mut a: i32; } s2;
    s1.a = 10;
    s2.a = 20;
    if (s1.a != 10) { return 3; }
    if (s2.a != 20) { return 4; }

    return 0;
}
