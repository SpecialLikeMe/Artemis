// PASS: error.Name(expr) carries a payload accessible via e.payload in the except handler.
@unsafe extern fn printf(fmt: *i8, ...) i32;

fn maybe_fail(x: i32) !i32 {
    if (x == 0) {
        return error.BadInput("zero is not allowed");
    }
    return x * 2;
}

pub fn main() i32 {
    let mut result: i32= 0;

    // Error path: payload should be non-null
    maybe_fail(0) catch |e| {
        if (e.payload != (i8*)0) { result = result + 1; }
    }

    // Success path: result should be 10, handler should not run
    let mut v: i32= maybe_fail(5) catch |e| { result = result + 99; };
    if (v != 10) { return 2; }

    if (result != 1) { return 3; }
    return 0;
}
