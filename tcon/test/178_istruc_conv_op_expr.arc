// Conversion operators in expression contexts
istruc Celsius {
    let mut degrees: f64;
    fn __construct__(self: *Celsius, d: f64) void { self.degrees = d; }
    fn operator_i32(self: *const Celsius) i32 { return (i32)self.degrees; }
}

istruc Fraction {
    let mut n: i32;
    let mut d: i32;
    fn __construct__(self: *Fraction, num: i32, den: i32) void { self.n = num; self.d = den; }
    fn operator_i32(self: *const Fraction) i32 { return self.n / self.d; }
}

pub fn main() i32 {
    let mut c: Celsius(100.0);
    if ((i32)c != 100) { return 1; }

    let mut warm: Celsius(37.5);
    if ((i32)warm != 37) { return 2; }

    let mut f: Fraction(7, 2);
    if ((i32)f != 3) { return 3; }

    let mut g: Fraction(10, 3);
    if ((i32)g != 3) { return 4; }
    return 0;
}
