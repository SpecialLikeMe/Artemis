pub fn main() i32 {
    let mut a: u64= 4000000000;
    let mut b: u64= 4000000000;
    let mut c: u64= a + b;
    if (c != 8000000000) { return 1; }
    let mut d: u64= c / 2;
    if (d != 4000000000) { return 2; }
    return 0;
}
