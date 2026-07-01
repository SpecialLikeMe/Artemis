// Conversion operators in expression contexts
istruc Celsius {
    f64 degrees;
    void __construct__(Celsius* self, f64 d) { self.degrees = d; }
    operator i32(const Celsius* self) { return (i32)self.degrees; }
}

istruc Fraction {
    i32 n;
    i32 d;
    void __construct__(Fraction* self, i32 num, i32 den) { self.n = num; self.d = den; }
    operator i32(const Fraction* self) { return self.n / self.d; }
}

i32 main() {
    Celsius c(100.0);
    if ((i32)c != 100) { return 1; }

    Celsius warm(37.5);
    if ((i32)warm != 37) { return 2; }

    Fraction f(7, 2);
    if ((i32)f != 3) { return 3; }

    Fraction g(10, 3);
    if ((i32)g != 3) { return 4; }
    return 0;
}
