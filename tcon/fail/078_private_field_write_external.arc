// FAIL: writing to a private field from outside the class
istruc Counter {
    private i32 count;
    public void __construct__(&self) { self.count = 0; }
}
i32 main() {
    Counter c;
    c.count = 10;  // ERROR: count is private
    return 0;
}
