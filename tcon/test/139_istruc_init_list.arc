// Member initializer lists removed; use direct assignments in constructor body.
istruc Pair {
    let mut first: i32;
    let mut second: i32;

    fn __construct__(self: *Pair, a: i32, b: i32) void {
        self.first  = a;
        self.second = b;
    }

    fn sum(self: *const Pair) i32 {
        return self.first + self.second;
    }

    fn product(self: *const Pair) i32 {
        return self.first * self.second;
    }
}

istruc Triple {
    let mut a: i32;
    let mut b: i32;
    let mut c: i32;

    fn __construct__(self: *Triple, x: i32, y: i32, z: i32) void {
        self.a = x;
        self.b = y;
        self.c = z;
    }

    fn total(self: *const Triple) i32 {
        return self.a + self.b + self.c;
    }
}

pub fn main() i32 {
    let mut p: Pair(3, 7);
    if (p.first   != 3)  { return 1; }
    if (p.second  != 7)  { return 2; }
    if (p.sum()   != 10) { return 3; }
    if (p.product()!= 21){ return 4; }

    let mut t: Triple(1, 2, 3);
    if (t.a      != 1) { return 5; }
    if (t.b      != 2) { return 6; }
    if (t.c      != 3) { return 7; }
    if (t.total()!= 6) { return 8; }

    return 0;
}
