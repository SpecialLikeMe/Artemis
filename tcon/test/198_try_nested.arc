// Test nested error propagation: inner function fails, outer catches with except
fn inner_fn(x: i32) !i32 {
    if (x < 0) {
        return error.Negative;
    }
    return x + 1;
}

fn outer_fn(x: i32) !i32 {
    // try propagates error from inner_fn to outer_fn's caller
    let mut v: i32= try inner_fn(x);
    return v * 2;
}

pub fn main() i32 {
    let mut outer_err: i32= 0;

    // inner_fn(-1) fails -> try propagates -> outer_fn fails -> except fires
    outer_fn(-1) catch |e| {
        outer_err = 1;
    }
    if (outer_err != 1) { return 1; }

    // inner_fn(3) succeeds -> outer_fn returns 8 -> except does NOT fire
    outer_fn(3) catch |e| {
        outer_err = 99;
    }
    if (outer_err != 1) { return 2; }

    return 0;
}
