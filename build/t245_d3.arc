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
    i32 t = Counter.total;
    i32 gt = Counter.get_total();
    if (t != 2) { return 1; }       // Counter.total
    if (gt != 2) { return 2; }      // get_total()
    if (c.get() != 10) { return 3; }
    if (d.get() != 20) { return 4; }
    return 0;
}
