// PASS: istruc constructor is only invoked via (), not {}.
// Brace after type+name is a parse error, not a constructor call.
istruc Counter {
    let mut n: i32;
    fn __construct__(self: *Counter, v: i32) void { self.n = v; }
    fn get(self: *Counter) i32 { return self.n; }
}
pub fn main() i32 {
    let mut c: Counter(10);
    if (c.get() != 10) { return 1; }
    // Zero-initialized without parens
    let mut d: Counter;
    d.n = 5;
    if (d.get() != 5) { return 2; }
    return 0;
}
