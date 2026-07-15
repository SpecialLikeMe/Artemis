// PASS: istruc constructor is only invoked via (), not {}.
// Brace after type+name is a parse error, not a constructor call.
istruc Counter {
    i32 n;
    void __construct__(Counter* self, i32 v) { self.n = v; }
    i32 get(Counter* self) { return self.n; }
}
i32 main() {
    Counter c(10);
    if (c.get() != 10) { return 1; }
    // Zero-initialized without parens
    Counter d;
    d.n = 5;
    if (d.get() != 5) { return 2; }
    return 0;
}
