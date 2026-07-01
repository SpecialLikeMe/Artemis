// FAIL: calling a class method with too many arguments
istruc Calc {
    i32 double_val(&const self, i32 a) { return a * 2; }
}
i32 main() {
    Calc c;
    return c.double_val(1, 2, 3);  // ERROR: double_val expects 1 arg, got 3
}
