istruc Counter {
    static i32 total;
    void __construct__(Counter* self, i32 v) {
        Counter.total = Counter.total + 1;
    }
}
i32 main() {
    Counter c(5);
    if (Counter.total != 1) { return 10; }
    Counter d(6);
    if (Counter.total != 2) { return 20; }
    return 0;
}
