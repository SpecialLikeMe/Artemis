pub fn main() i32 {
    let mut a: u32= 100;
    let mut b: u32= 37;
    if (a + b != 137) { return 1; }
    if (a - b != 63)  { return 2; }
    if (a * b != 3700) { return 3; }
    if (a / b != 2)   { return 4; }
    if (a % b != 26)  { return 5; }
    return 0;
}
