istruc Num {
    let mut v: i32;
    fn __construct__(self: *Num, a: i32) void { self.v = a; }
    fn get(self: *const Num) i32 { return self.v; }
}
pub fn main() i32 {
    let mut n: Num(42);
    if (n.get() != 42) { return 1; }
    return 0;
}
