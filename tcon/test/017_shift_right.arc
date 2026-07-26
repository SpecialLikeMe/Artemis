pub fn main() i32 {
    let mut a: i32= 128;
    let mut b: i32= a >> 3;
    if (b != 16)  { return 1; }
    let mut c: u32= 256;
    let mut d: u32= c >> 4;
    if (d != 16)  { return 2; }
    return 0;
}
