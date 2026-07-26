// FAIL: calling __construct__ explicitly without comptime must be rejected
istruc Pt { let mut x: i32; fn __construct__(self: *Pt, v: i32) void { self.x = v; } }
fn main() i32 {
    let mut p: Pt;
    p.__construct__(5);  // ERROR: need comptime Pt p;
    return p.x;
}
