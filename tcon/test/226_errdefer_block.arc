// Test: errdefer block form and try propagation.

let mut fired: i32= 0;

fn inner() !i32 {
    return error.Bad;
}

fn outer() !i32 {
    errdefer { fired = fired + 1; }
    try inner();
    return 0;
}

pub fn main() i32 {
    // errdefer in outer() should fire when try propagates the error
    fired = 0;
    outer();
    if (fired != 1) { return 1; }

    return 0;
}
