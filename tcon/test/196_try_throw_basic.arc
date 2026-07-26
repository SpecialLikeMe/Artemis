// Test basic error-union: function returns error, caught with except
fn maybe_divide(a: i32, b: i32) !i32 {
    if (b == 0) {
        return error.DivByZero;
    }
    return a / b;
}

pub fn main() i32 {
    let mut err_fired: i32= 0;

    // This call fails: handler should fire
    maybe_divide(10, 0) catch |e| {
        err_fired = 1;
    }
    if (err_fired != 1) { return 1; }

    // This call succeeds: handler should NOT fire
    maybe_divide(10, 2) catch |e| {
        err_fired = 99;
    }
    if (err_fired != 1) { return 2; }

    return 0;
}
