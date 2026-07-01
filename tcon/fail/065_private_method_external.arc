// FAIL: calling a private method from outside the class
istruc Util {
    private i32 compute(&const self) { return 42; }
}
i32 main() {
    Util u;
    return u.compute();  // ERROR: compute is private
}
