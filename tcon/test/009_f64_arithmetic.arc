pub fn main() i32 {
    let mut a: f64= 3.14;
    let mut b: f64= 2.0;
    let mut c: f64= a * b;
    if (c != 6.28) { return 1; }
    let mut d: f64= a / b;
    if (d != 1.57) { return 2; }
    return 0;
}
