istruc Ratio {
    i32 num;
    i32 den;

    void __construct__(&self, i32 n, i32 d) {
        self.num = n;
        self.den = d;
    }

    operator i32(&const self) {
        return self.num / self.den;
    }
}

i32 main() {
    Ratio r(10, 3);

    i32 v = (i32)r;
    if (v != 3) { return 1; }

    Ratio r2(20, 4);
    i32 v2 = (i32)r2;
    if (v2 != 5) { return 2; }

    return 0;
}
