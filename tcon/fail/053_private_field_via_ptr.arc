// FAIL: accessing a private field via class pointer from outside the class
istruc Safe {
    private i32 pin;
    public void __construct__(Safe* self, i32 p) { self.pin = p; }
}
i32 main() {
    Safe s(1234);
    Safe* p = &s;
    i32 x = p->pin;  // ERROR: pin is private
    return x;
}
