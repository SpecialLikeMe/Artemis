// FAIL: calling __construct__ on an implicitly-constructed variable
istruc Box { let mut v: i32; fn __construct__(self: *Box, x: i32) void { self.v = x; } }
fn main() i32 {
    fn b(10) Box;
    b.__construct__(20);  // ERROR: b was not declared comptime
    return b.v;
}
