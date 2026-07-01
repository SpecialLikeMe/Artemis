// Test: explicit self parameter — any name, any pointer-to-class type accepted
istruc Counter {
    i32 value;

    void __construct__(Counter* self) { self.value = 0; }

    // 'self' is just the conventional name; any name works
    void increment(Counter* me) { me.value = me.value + 1; }
    void add(Counter* c, i32 n)  { c.value = c.value + n; }

    i32 get(const Counter* reader) { return reader.value; }

    // 'this' keyword as type alias for enclosing class
    void reset(this* self) { self.value = 0; }
}

istruc Pair {
    i32 a;
    i32 b;

    i32 sum(const Pair* p)  { return p.a + p.b; }
    i32 diff(const Pair* p) { return p.a - p.b; }
}

i32 main() {
    Counter c;
    c.increment();
    c.increment();
    if (c.get() != 2)  { return 1; }

    c.add(8);
    if (c.get() != 10) { return 2; }

    c.reset();
    if (c.get() != 0)  { return 3; }

    Pair p;
    p.a = 7;
    p.b = 3;
    if (p.sum()  != 10) { return 4; }
    if (p.diff() != 4)  { return 5; }

    return 0;
}
