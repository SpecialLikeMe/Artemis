// FAIL: comptime declaration cannot also pass constructor arguments at declaration site
istruc Pt { let mut x: i32; fn __construct__(self: *Pt, v: i32) void { self.x = v; } }
fn main() i32 {
    comptime Pt p(5);  // ERROR: comptime means user calls __construct__ explicitly
    return p.x;
}
