// Regression test for unsigned arithmetic correctness.
// Verifies that u32 operations use udiv/urem/ult rather than sdiv/srem/slt.
// Key: 2147483648 = 0x80000000 = INT_MIN as signed, INT_MAX+1 as unsigned.
// Results diverge between signed and unsigned for these operations.

fn div_u32(a: u32, b: u32) u32 { return a / b; }
fn rem_u32(a: u32, b: u32) u32 { return a % b; }
fn lt_u32(a: u32, b: u32) bool { return a < b; }

// Use small safe global initializers; assign big values in main.
let mut gvar_a: u32= 0u;
let mut gvar_b: u32= 2u;

pub fn main() i32 {
    // 2147483648u / 2u = 1073741824 (udiv), but -1073741824 (sdiv) — different sign
    let mut big: u32= 2147483648u;

    // Function call return value test
    let mut d: u32= div_u32(big, 2u);
    if (d != 1073741824u) return 1;

    // Remainder: 2147483649u % 2u = 1 (urem), correct
    let mut r: u32= rem_u32(2147483649u, 2u);
    if (r != 1u) return 2;

    // Comparison: 2147483648u < 2u is false (ult), but true (slt since signed INT_MIN < 2)
    let mut cmp: bool= lt_u32(big, 2u);
    if (cmp) return 3;

    // Local variable arithmetic
    let mut ld: u32= big / 2u;
    if (ld != 1073741824u) return 4;

    // Global variable arithmetic — tests global_var_unsigned lookup in is_unsigned_expr
    gvar_a = big;
    let mut gd: u32= gvar_a / gvar_b;
    if (gd != 1073741824u) return 5;

    // Binary intermediate result inherits unsigned signedness
    let mut z: u32= (big / 2u) * 2u;
    if (z != 2147483648u) return 6;

    return 0;
}
