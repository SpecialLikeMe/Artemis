// FAIL: using a private operator overload from outside the class
istruc Val {
    let mut n: i32;
    public void __construct__(Val* self, i32 x) { self.n = x; }
    private Val operator+(const Val* self, Val other) {
        let mut r: Val;
        r.n = self.n + other.n;
        return r;
    }
}
fn main() i32 {
    fn a(1) Val;
    fn b(2) Val;
    let mut c: Val= a + b;  // ERROR: operator+ is private
    return c.n;
}
