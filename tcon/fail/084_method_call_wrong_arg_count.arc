// FAIL: calling a class method with wrong number of arguments
istruc Calc {
    i32 add(&const self, i32 a, i32 b) { return a + b; }
}
i32 main() {
    Calc c;
    return c.add(1);  // ERROR: add expects 2 args, got 1
}
