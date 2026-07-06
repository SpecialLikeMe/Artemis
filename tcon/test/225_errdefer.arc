// Test: errdefer — executes only on error exit, not on success.

i32 fired = 0;

auto maybe_fail(i32 should_fail) !i32 {
    errdefer fired = 1;
    if (should_fail) {
        return error.Fail;
    }
    return 42;
}

i32 main() {
    // Success path: errdefer must NOT fire
    fired = 0;
    maybe_fail(0);
    if (fired != 0) { return 1; }

    // Error path: errdefer MUST fire
    fired = 0;
    maybe_fail(1);
    if (fired != 1) { return 2; }

    return 0;
}
