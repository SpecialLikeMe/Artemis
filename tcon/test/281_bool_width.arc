// PASS: bN arbitrary-width booleans with correct cast behavior
pub fn main() i32 {
    let x: b1 = true;
    let y: b8 = false;
    let z: b32 = true;
    if (!x) { return 1; }
    if (y)  { return 2; }
    if (!z) { return 3; }
    // b1 cast to i32 must be 1 (zero-extend), not -1 (sign-extend)
    if ((x as i32) != 1) { return 4; }
    if ((y as i32) != 0) { return 5; }
    if ((z as i32) != 1) { return 6; }
    return 0;
}
