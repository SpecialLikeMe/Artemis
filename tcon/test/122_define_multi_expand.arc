@define <ZERO> <0>

pub fn main() i32 {
    let mut a: i32= ZERO;
    let mut b: i32= ZERO;
    let mut c: i32= ZERO;
    if (a != 0) { return 1; }
    if (b != 0) { return 2; }
    if (c != 0) { return 3; }
    if (a + b + c != 0) { return 4; }
    return 0;
}
