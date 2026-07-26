// FAIL: calling a class method with too many arguments
istruc Calc {
    fn double_val(self: *const Calc, a: i32) i32 { return a * 2; }
}
fn main() i32 {
    let mut c: Calc;
    return c.double_val(1, 2, 3);  // ERROR: double_val expects 1 arg, got 3
}
