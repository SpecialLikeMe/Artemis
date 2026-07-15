int printf(i8* fmt, ...);
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
    Counter c(10);
    Counter d(20);
    printf("total field=%d
", Counter.total);
    printf("get_total=%d
", Counter.get_total());
    return 0;
}
