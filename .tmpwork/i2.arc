istruc P {
    let mut x: i32;
    fn __construct__(self: *P, a: i32) void { self.x = a; }
    fn sum(self: *const P) i32 { return self.x; }
}
pub fn main() i32 {
    let mut p: P(3);
    if (p.sum() != 3) { return 1; }
    return 0;
}
