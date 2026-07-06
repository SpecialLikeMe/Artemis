// Test basic error-union: function returns error, caught with except
auto maybe_divide(i32 a, i32 b) !i32 {
    if (b == 0) {
        return error.DivByZero;
    }
    return a / b;
}

i32 main() {
    i32 err_fired = 0;

    // This call fails: handler should fire
    maybe_divide(10, 0) except |e| {
        err_fired = 1;
    }
    if (err_fired != 1) { return 1; }

    // This call succeeds: handler should NOT fire
    maybe_divide(10, 2) except |e| {
        err_fired = 99;
    }
    if (err_fired != 1) { return 2; }

    return 0;
}
