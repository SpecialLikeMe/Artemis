// std.math — basic math functions
extern std.math;

extern f64 sqrt(f64 x);
extern f64 fabs(f64 x);

i32 main() {
    // abs
    if (math::abs_i32(-7) != 7) { return 1; }
    if (math::abs_i64((i64)-999) != (i64)999) { return 2; }

    // min / max
    if (math::min_i32(3, 5) != 3) { return 3; }
    if (math::max_i32(3, 5) != 5) { return 4; }
    if (math::min_i64((i64)100, (i64)200) != (i64)100) { return 5; }
    if (math::max_i64((i64)100, (i64)200) != (i64)200) { return 6; }

    // clamp
    if (math::clamp_i32(10, 0, 5) != 5) { return 7; }
    if (math::clamp_i32(-3, 0, 5) != 0) { return 8; }
    if (math::clamp_i32(3, 0, 5) != 3) { return 9; }

    // math::is_power_of_two
    if (!math::is_power_of_two((u64)1024)) { return 10; }
    if (math::is_power_of_two((u64)1000))  { return 11; }

    // math::gcd / math::lcm
    if (math::gcd(12, 8) != 4) { return 12; }
    if (math::lcm(4, 6) != 12) { return 13; }

    return 0;
}
