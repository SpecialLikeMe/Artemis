// std.math — basic math functions
extern  std.math;

@unsafe extern fn sqrt(x: f64) f64;
@unsafe extern fn fabs(x: f64) f64;

pub fn main() i32 {
    // abs
    if (std.math.abs_i32(-7) != 7) { return 1; }
    if (std.math.abs_i64((i64)-999) != (i64)999) { return 2; }

    // min / max
    if (std.math.min_i32(3, 5) != 3) { return 3; }
    if (std.math.max_i32(3, 5) != 5) { return 4; }
    if (std.math.min_i64((i64)100, (i64)200) != (i64)100) { return 5; }
    if (std.math.max_i64((i64)100, (i64)200) != (i64)200) { return 6; }

    // clamp
    if (std.math.clamp_i32(10, 0, 5) != 5) { return 7; }
    if (std.math.clamp_i32(-3, 0, 5) != 0) { return 8; }
    if (std.math.clamp_i32(3, 0, 5) != 3) { return 9; }

    // std.math.is_power_of_two
    if (!std.math.is_power_of_two((u64)1024)) { return 10; }
    if (std.math.is_power_of_two((u64)1000))  { return 11; }

    // std.math.gcd / std.math.lcm
    if (std.math.gcd(12, 8) != 4) { return 12; }
    if (std.math.lcm(4, 6) != 12) { return 13; }

    return 0;
}
