// Multiple operator overloads: -, *, !=
istruc Vec {
    let mut x: i32;
    fn __construct__(self: *Vec, v: i32) void { self.x = v; }
    fn operator-(self: *const Vec, rhs: Vec) Vec {
        let mut r: Vec;
        r.x = self.x - rhs.x;
        return r;
    }
    fn operator*(self: *const Vec, s: i32) Vec {
        let mut r: Vec;
        r.x = self.x * s;
        return r;
    }
    fn operator!=(self: *const Vec, rhs: Vec) bool {
        return self.x != rhs.x;
    }
    fn operator<(self: *const Vec, rhs: Vec) bool {
        return self.x < rhs.x;
    }
}

pub fn main() i32 {
    let mut a: Vec(10);
    let mut b: Vec(3);

    let mut c: Vec= a - b;
    if (c.x != 7)  { return 1; }

    let mut d: Vec= a * 4;
    if (d.x != 40) { return 2; }

    if (!(a != b)) { return 3; }
    if (!(b < a))  { return 4; }
    return 0;
}
