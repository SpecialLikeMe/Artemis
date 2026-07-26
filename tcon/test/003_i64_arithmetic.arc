pub fn main() i32 {
    let mut a: i64= 1000000000;
    let mut b: i64= 2000000000;
    let mut c: i64= a + b;
    if (c != 3000000000) { return 1; }
    let mut d: i64= b - a;
    if (d != 1000000000) { return 2; }
    return 0;
}
