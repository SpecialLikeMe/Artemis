istruc Counter {
    i32 value;

    void __construct__(Counter* self, i32 v) {
        self.value = v;
    }

    static i32 zero() {
        return 0;
    }

    static i32 add(i32 a, i32 b) {
        return a + b;
    }

    i32 get(const Counter* self) {
        return self.value;
    }

    void inc(Counter* self) {
        self.value = self.value + 1;
    }
}

i32 main() {
    if (Counter.zero()     != 0)  { return 1; }
    if (Counter.add(3, 4)  != 7)  { return 2; }
    if (Counter.add(10, 5) != 15) { return 3; }

    Counter c(10);
    c.inc();
    if (c.get() != 11) { return 4; }

    return 0;
}
