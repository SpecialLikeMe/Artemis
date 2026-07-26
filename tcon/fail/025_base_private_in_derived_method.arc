// FAIL: derived class method cannot read base private field
istruc Base {
    private i32 x;
    public void __construct__(Base* self, i32 v) { self.x = v; }
}
istruc Child : Base {
    fn read(self: *const Child) i32 { return self.x; }  // ERROR: x is private in Base
}
fn main() i32 { return 0; }
