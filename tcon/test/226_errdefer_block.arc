// Test: errdefer block form and try propagation.

i32 fired = 0;

auto inner() !i32 {
    return error.Bad;
}

auto outer() !i32 {
    errdefer { fired = fired + 1; }
    try inner();
    return 0;
}

i32 main() {
    // errdefer in outer() should fire when try propagates the error
    fired = 0;
    outer();
    if (fired != 1) { return 1; }

    return 0;
}
