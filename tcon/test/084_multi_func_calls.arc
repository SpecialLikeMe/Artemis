fn add(a: i32, b: i32) i32 { return a + b; }
fn mul(a: i32, b: i32) i32 { return a * b; }
fn sub(a: i32, b: i32) i32 { return a - b; }

pub fn main() i32 {
    let mut r: i32= add(mul(2, 3), sub(10, 4));
    if (r != 12) { return 1; }
    let mut s: i32= mul(add(1, 2), add(3, 4));
    if (s != 21) { return 2; }
    return 0;
}
