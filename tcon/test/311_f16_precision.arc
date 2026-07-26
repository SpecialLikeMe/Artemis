// PASS: f16 half-precision float type works correctly.
// Requires F16C CPU feature (auto-detected by compiler).
pub fn main() i32 {
    let mut x: f16 = 1.5;
    let mut y: f16 = 0.5;
    let z: f16 = x + y;
    if (z < 1.9 || z > 2.1) { return 1; }
    // Check size: f16 = 2 bytes
    if (@csizeof(f16) != 2) { return 2; }
    return 0;
}
