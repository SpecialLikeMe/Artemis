istruc Counter {
    static i32 total;
    i32 n;
    void __construct__(Counter* self, i32 v) {
        self.n = v;
        Counter.total = Counter.total + 1;
    }
    static i32 get_total() { return Counter.total; }
}
i32 main() {
    Counter.total = 99;
    i32 gt = Counter.get_total();
    if (gt != 99) { return 1; }
    return 0;
}
