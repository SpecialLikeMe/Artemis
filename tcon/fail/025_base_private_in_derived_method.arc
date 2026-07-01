// FAIL: derived class method cannot read base private field
istruc Base {
    private i32 x;
    public void __construct__(&self, i32 v) { self.x = v; }
}
istruc Child : Base {
    i32 read(&const self) { return self.x; }  // ERROR: x is private in Base
}
i32 main() { return 0; }
