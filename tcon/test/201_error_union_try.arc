// try propagates error from callee; on success yields the value
fn safe_div(a: i32, b: i32) !i32 {
    if (b == 0) { return error.DivByZero; }
    return a / b;
}

fn caller(a: i32, b: i32) !i32 {
    let mut result: i32= try safe_div(a, b);
    return result;
}

pub fn main() i32 {
    let mut err_fired: i32= 0;

    // propagated error hits the except handler
    caller(10, 0) catch |e| {
        err_fired = 1;
    }
    if (err_fired != 1) { return 1; }

    // successful path: handler must NOT fire
    caller(10, 2) catch |e| {
        err_fired = 99;
    }
    if (err_fired != 1) { return 2; }

    return 0;
}
