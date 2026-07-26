// FAIL: calling a private method from outside the class
istruc Util {
    private i32 compute(const Util* self) { return 42; }
}
fn main() i32 {
    let mut u: Util;
    return u.compute();  // ERROR: compute is private
}
