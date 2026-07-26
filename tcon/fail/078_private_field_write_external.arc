// FAIL: writing to a private field from outside the class
istruc Counter {
    private i32 count;
    public void __construct__(Counter* self) { self.count = 0; }
}
fn main() i32 {
    let mut c: Counter;
    c.count = 10;  // ERROR: count is private
    return 0;
}
