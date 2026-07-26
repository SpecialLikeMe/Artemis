pub fn main() i32 {
    let mut a: i32= 1;
    let mut b: i32= a << 4;
    if (b != 16)  { return 1; }
    let mut c: i32= 3 << 3;
    if (c != 24)  { return 2; }
    return 0;
}
