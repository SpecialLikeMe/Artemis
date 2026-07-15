// PASS: derive proc macro — declared as derive function, applied via #derive[name]
// The macro is a pass-through; the decorated istruc compiles and runs normally.

tokenstream* add_default(&memstr alloc, tokenstream* input) derive {
    return input;
}

#derive[add_default]
istruc Counter {
    i32 count;
    void __construct__(Counter* self) { self.count = 0; }
    void inc(Counter* self) { self.count = self.count + 1; }
    i32 get(Counter* self) { return self.count; }
}

i32 main() {
    Counter c();
    c.inc();
    c.inc();
    c.inc();
    if (c.get() != 3) { return 1; }
    return 0;
}
