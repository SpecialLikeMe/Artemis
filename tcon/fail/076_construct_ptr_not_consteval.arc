// FAIL: calling __construct__ via pointer on a non-comptime variable
istruc Node { let mut v: i32; fn __construct__(self: *Node, x: i32) void { self.v = x; } }
fn main() i32 {
    fn n(1) Node;
    let mut p: *Node= &n;
    p->__construct__(2);  // ERROR: n is not declared comptime
    return n.v;
}
