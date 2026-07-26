// FAIL: using a private conversion operator from outside the class
istruc Num {
    let mut v: i32;
    public void __construct__(Num* self, i32 x) { self.v = x; }
    private operator i32(const Num* self) { return self.v; }
}
fn main() i32 {
    fn n(5) Num;
    let mut x: i32= (i32)n;  // ERROR: operator i32 is private
    return x;
}
