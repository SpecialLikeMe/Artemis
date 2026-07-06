// Regression test for unsigned arithmetic correctness.
// Verifies that u32 operations use udiv/urem/ult rather than sdiv/srem/slt.
// Key: 2147483648 = 0x80000000 = INT_MIN as signed, INT_MAX+1 as unsigned.
// Results diverge between signed and unsigned for these operations.

u32 div_u32(u32 a, u32 b) { return a / b; }
u32 rem_u32(u32 a, u32 b) { return a % b; }
bool lt_u32(u32 a, u32 b) { return a < b; }

// Use small safe global initializers; assign big values in main.
u32 gvar_a = 0u;
u32 gvar_b = 2u;

i32 main() {
    // 2147483648u / 2u = 1073741824 (udiv), but -1073741824 (sdiv) — different sign
    u32 big = 2147483648u;

    // Function call return value test
    u32 d = div_u32(big, 2u);
    if (d != 1073741824u) return 1;

    // Remainder: 2147483649u % 2u = 1 (urem), correct
    u32 r = rem_u32(2147483649u, 2u);
    if (r != 1u) return 2;

    // Comparison: 2147483648u < 2u is false (ult), but true (slt since signed INT_MIN < 2)
    bool cmp = lt_u32(big, 2u);
    if (cmp) return 3;

    // Local variable arithmetic
    u32 ld = big / 2u;
    if (ld != 1073741824u) return 4;

    // Global variable arithmetic — tests global_var_unsigned lookup in is_unsigned_expr
    gvar_a = big;
    u32 gd = gvar_a / gvar_b;
    if (gd != 1073741824u) return 5;

    // Binary intermediate result inherits unsigned signedness
    u32 z = (big / 2u) * 2u;
    if (z != 2147483648u) return 6;

    return 0;
}
