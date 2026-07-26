pub fn main() i32 {
    let mut a: i32= 0xFF;
    let mut b: i32= 0x0F;
    let mut c: i32= a ^ b;
    if (c != 0xF0) { return 1; }
    let mut x: i32= 5 ^ 5;
    if (x != 0)    { return 2; }
    return 0;
}
