// FAIL: calling __construct__ on variable declared with implicit ctor (not consteval)
istruc Timer {
    i32 ms;
    void __construct__(Timer* self, i32 t) { self.ms = t; }
}
i32 main() {
    Timer t(100);           // implicit ctor — valid
    t.__construct__(200);   // ERROR: t is not consteval
    return t.ms;
}
