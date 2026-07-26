istruc Ratio {
    let mut num: i32;
    let mut den: i32;

    fn __construct__(self: *Ratio, n: i32, d: i32) void {
        self.num = n;
        self.den = d;
    }

    fn operator_i32(self: *const Ratio) i32 {
        return self.num / self.den;
    }
}

pub fn main() i32 {
    let mut r: Ratio(10, 3);

    let mut v: i32= (i32)r;
    if (v != 3) { return 1; }

    let mut r2: Ratio(20, 4);
    let mut v2: i32= (i32)r2;
    if (v2 != 5) { return 2; }

    return 0;
}
