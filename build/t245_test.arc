istruc Counter {
    static i32 total;
    i32 n;
    void __construct__(Counter* self) { self.n = 0; Counter.total = Counter.total + 1; }
    static i32 get_total() { return Counter.total; }
}
i32 main() {
    Counter c;
    Counter d;
    if (Counter.get_total() != 2) { return 1; }
    return 0;
}
