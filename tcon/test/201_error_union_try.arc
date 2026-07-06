// try propagates error from callee; on success yields the value
auto safe_div(i32 a, i32 b) !i32 {
    if (b == 0) { return error.DivByZero; }
    return a / b;
}

auto caller(i32 a, i32 b) !i32 {
    i32 result = try safe_div(a, b);
    return result;
}

i32 main() {
    i32 err_fired = 0;

    // propagated error hits the except handler
    caller(10, 0) except |e| {
        err_fired = 1;
    }
    if (err_fired != 1) { return 1; }

    // successful path: handler must NOT fire
    caller(10, 2) except |e| {
        err_fired = 99;
    }
    if (err_fired != 1) { return 2; }

    return 0;
}
