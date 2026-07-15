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
    Counter c(5);
    if (Counter.total != 1) { return 10; }
    Counter d(6);
    if (Counter.total != 2) { return 20; }
    i32 gt = Counter.get_total();
    if (gt != 2) { return 30; }
    if (c.get() != 5) { return 40; }
    if (d.get() != 6) { return 50; }
    return 0;
}
