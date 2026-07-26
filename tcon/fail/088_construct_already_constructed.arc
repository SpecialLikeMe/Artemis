// FAIL: calling __construct__ on variable declared with implicit ctor (not comptime)
istruc Timer {
    let mut ms: i32;
    fn __construct__(self: *Timer, t: i32) void { self.ms = t; }
}
fn main() i32 {
    fn t(100) Timer;           // implicit ctor — valid
    t.__construct__(200);   // ERROR: t is not comptime
    return t.ms;
}
