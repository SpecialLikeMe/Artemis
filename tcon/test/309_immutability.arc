// PASS: immutable let variables can be read but not reassigned.
// Reassignment should produce a compile error, not silent success.
pub fn main() i32 {
    let x: i32 = 10;
    let mut y: i32 = 20;
    y = 30;
    if (y != 30) { return 1; }
    if (x != 10) { return 2; }
    return 0;
}
