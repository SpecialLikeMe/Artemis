// Test: errdefer — executes only on error exit, not on success.

let mut fired: i32= 0;

fn maybe_fail(should_fail: i32) !i32 {
    errdefer fired = 1;
    if (should_fail) {
        return error.Fail;
    }
    return 42;
}

pub fn main() i32 {
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
