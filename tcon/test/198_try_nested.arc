// Test nested error propagation: inner function fails, outer catches with except
auto inner_fn(i32 x) !i32 {
    if (x < 0) {
        return error.Negative;
    }
    return x + 1;
}

auto outer_fn(i32 x) !i32 {
    // try propagates error from inner_fn to outer_fn's caller
    i32 v = try inner_fn(x);
    return v * 2;
}

i32 main() {
    i32 outer_err = 0;

    // inner_fn(-1) fails -> try propagates -> outer_fn fails -> except fires
    outer_fn(-1) except |e| {
        outer_err = 1;
    }
    if (outer_err != 1) { return 1; }

    // inner_fn(3) succeeds -> outer_fn returns 8 -> except does NOT fire
    outer_fn(3) except |e| {
        outer_err = 99;
    }
    if (outer_err != 1) { return 2; }

    return 0;
}
