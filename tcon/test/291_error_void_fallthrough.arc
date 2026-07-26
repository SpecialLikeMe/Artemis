// PASS: !void functions that fall through (no explicit return) are implicitly success
fn validate(x: i32) !void {
    if (x < 0) {
        return error.Negative;
    }
    // implicit success — no return statement needed
}

fn check_range(lo: i32, hi: i32, val: i32) !void {
    if (val < lo) { return error.TooLow; }
    if (val > hi) { return error.TooHigh; }
    // fallthrough = success
}

pub fn main() i32 {
    let mut err_count: i32 = 0;

    validate(-1) catch |e| { err_count = err_count + 1; }
    if (err_count != 1) { return 1; }

    validate(5) catch |e| { err_count = 99; }
    if (err_count != 1) { return 2; }

    check_range(0, 10, -1) catch |e| { err_count = err_count + 1; }
    if (err_count != 2) { return 3; }

    check_range(0, 10, 11) catch |e| { err_count = err_count + 1; }
    if (err_count != 3) { return 4; }

    check_range(0, 10, 5) catch |e| { err_count = 99; }
    if (err_count != 3) { return 5; }

    return 0;
}
