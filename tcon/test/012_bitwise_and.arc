pub fn main() i32 {
    let mut a: i32= 0xFF;
    let mut b: i32= 0x0F;
    let mut c: i32= a & b;
    if (c != 0x0F) { return 1; }
    let mut d: i32= 0xAA & 0x55;
    if (d != 0)    { return 2; }
    return 0;
}
