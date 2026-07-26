fn greet() void  { return; }
fn add(a: i32, b: i32) i32  { return a + b; }
istruc W {
    let mut v: i32;
    fn get(self: *const W) i32  { return self.v; }
}
pub fn main() i32 {
    greet();
    if (add(2, 3) != 5) { return 1; }
    let mut w: W;
    w.v = 9;
    if (w.get() != 9) { return 2; }
    return 0;
}
