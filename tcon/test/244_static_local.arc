// PASS: static local variable persists across function calls.
fn counter() i32 {
    let mut n: static i32= 0;
    n = n + 1;
    return n;
}
pub fn main() i32 {
    if (counter() != 1) { return 1; }
    if (counter() != 2) { return 2; }
    if (counter() != 3) { return 3; }
    return 0;
}
