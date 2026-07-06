// FAIL: 'try' inside a noexcept function is forbidden
auto maybe_fail() !i32 {
    return error.Oops;
}

i32 run() noexcept {
    i32 v = try maybe_fail();  // must error
    return v;
}

i32 main() { return run(); }
