pub fn main() i32 {
    let mut a: i32= 0xF0;
    let mut b: i32= 0x0F;
    let mut c: i32= a | b;
    if (c != 0xFF) { return 1; }
    let mut d: i32= 0 | 42;
    if (d != 42)   { return 2; }
    return 0;
}
