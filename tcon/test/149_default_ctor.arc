istruc Counter {
    let mut n: i32;
    fn __construct__(self: *Counter) void { self.n = 100; }
    fn get(self: *const Counter) i32 { return self.n; }
}
pub fn main() i32 {
    let mut c: Counter();
    if (c.get() != 100) { return 1; }
    return 0;
}
