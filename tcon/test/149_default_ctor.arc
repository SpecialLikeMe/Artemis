istruc Counter {
    i32 n;
    void __construct__(Counter* self) { self.n = 100; }
    i32 get(const Counter* self) { return self.n; }
}
i32 main() {
    Counter c;
    if (c.get() != 100) { return 1; }
    return 0;
}
