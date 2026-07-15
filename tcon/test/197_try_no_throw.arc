// Test error-union function that always succeeds — handler must not run
auto add(i32 a, i32 b) !i32 {
    return a + b;
}

i32 main() {
    i32 err_fired = 0;

    add(3, 4) catch |e| {
        err_fired = 1;
    }

    if (err_fired != 0) { return 1; }
    return 0;
}
