// FAIL: accessing a private field via class pointer from outside the class
istruc Safe {
    private i32 pin;
    public void __construct__(Safe* self, i32 p) { self.pin = p; }
}
fn main() i32 {
    fn s(1234) Safe;
    let mut p: *Safe= &s;
    let mut x: i32= p->pin;  // ERROR: pin is private
    return x;
}
