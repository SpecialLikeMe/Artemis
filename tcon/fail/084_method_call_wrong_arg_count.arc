// FAIL: calling a class method with wrong number of arguments
istruc Calc {
    fn add(self: *const Calc, a: i32, b: i32) i32 { return a + b; }
}
fn main() i32 {
    let mut c: Calc;
    return c.add(1);  // ERROR: add expects 2 args, got 1
}
