pub fn main() i32 {
    let mut a: i32= 10;
    let mut b: i32= 20;
    let mut mx: i32= a > b ? a : b;
    if (mx != 20) { return 1; }
    let mut mn: i32= a < b ? a : b;
    if (mn != 10) { return 2; }
    let mut c: i32= 0 ? 99 : 42;
    if (c != 42)  { return 3; }
    return 0;
}
