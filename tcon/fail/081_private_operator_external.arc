// FAIL: using a private operator overload from outside the class
istruc Val {
    i32 n;
    public void __construct__(&self, i32 x) { self.n = x; }
    private Val operator+(&const self, Val other) {
        Val r;
        r.n = self.n + other.n;
        return r;
    }
}
i32 main() {
    Val a(1);
    Val b(2);
    Val c = a + b;  // ERROR: operator+ is private
    return c.n;
}
