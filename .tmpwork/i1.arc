istruc P {
    let mut x: i32;
    fn sum(self: *const P) i32 { return self.x; }
}
pub fn main() i32 {
    let mut p: P;
    p.x = 3;
    if (p.sum() != 3) { return 1; }
    return 0;
}
