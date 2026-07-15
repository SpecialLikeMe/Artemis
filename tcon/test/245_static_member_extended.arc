// PASS: extended static member tests — static fields and static methods on istruc
istruc Counter {
    static i32 total;
    i32 n;
    void __construct__(Counter* self, i32 v) {
        self.n = v;
        Counter.total = Counter.total + 1;
    }
    static i32 get_total() { return Counter.total; }
    i32 get(Counter* self) { return self.n; }
}

i32 main() {
    Counter c(10);
    Counter d(20);
    if (Counter.total != 2)         { return 1; }
    if (Counter.get_total() != 2)   { return 2; }
    if (c.get() != 10)              { return 3; }
    if (d.get() != 20)              { return 4; }
    // Static field is shared across instances
    Counter.total = 0;
    if (Counter.get_total() != 0)   { return 5; }
    return 0;
}
