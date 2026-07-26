pub fn main() i32 {
    let mut a: f32= 1.5;
    let mut b: f32= 2.5;
    let mut c: f32= a + b;
    if (c != 4.0) { return 1; }
    let mut d: f32= b - a;
    if (d != 1.0) { return 2; }
    let mut e: f32= a * b;
    if (e != 3.75) { return 3; }
    return 0;
}
