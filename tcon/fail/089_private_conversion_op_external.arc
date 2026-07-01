// FAIL: using a private conversion operator from outside the class
istruc Num {
    i32 v;
    public void __construct__(&self, i32 x) { self.v = x; }
    private operator i32(&const self) { return self.v; }
}
i32 main() {
    Num n(5);
    i32 x = (i32)n;  // ERROR: operator i32 is private
    return x;
}
