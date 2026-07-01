// std.math — basic math functions
extern std.math;

extern f64 sqrt(f64 x);
extern f64 fabs(f64 x);

i32 main() {
    // abs
    if (abs_i32(-7) != 7) { return 1; }
    if (abs_i64((i64)-999) != (i64)999) { return 2; }

    // min / max
    if (min_i32(3, 5) != 3) { return 3; }
    if (max_i32(3, 5) != 5) { return 4; }
    if (min_i64((i64)100, (i64)200) != (i64)100) { return 5; }
    if (max_i64((i64)100, (i64)200) != (i64)200) { return 6; }

    // clamp
    if (clamp_i32(10, 0, 5) != 5) { return 7; }
    if (clamp_i32(-3, 0, 5) != 0) { return 8; }
    if (clamp_i32(3, 0, 5) != 3) { return 9; }

    // is_power_of_two
    if (!is_power_of_two((u64)1024)) { return 10; }
    if (is_power_of_two((u64)1000))  { return 11; }

    // gcd / lcm
    if (gcd(12, 8) != 4) { return 12; }
    if (lcm(4, 6) != 12) { return 13; }

    return 0;
}
