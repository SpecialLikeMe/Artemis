// PASS: multiple attribute proc macros applied to the same function.
// Each macro injects a wrapper that calls the decorated function — proving
// the injected code can reference and use the decorated item's output.

fn trace(&memstr alloc, tokenstream* input) *tokenstream attr {
    return quote {
        fn trace_compute(x: i32) i32 { return compute(x) + 1000; }
    };
}

fn inline_hint(&memstr alloc, tokenstream* input) *tokenstream attr {
    return quote {
        fn hint_compute(x: i32) i32 { return compute(x) * 2; }
    };
}

fn no_inline(&memstr alloc, tokenstream* input) *tokenstream attr verify {
    return quote {
        fn no_inline_identity(x: i32) i32 { return identity(x) - 1; }
    };
}

#[trace]
#[inline_hint]
fn compute(x: i32) i32 {
    return x * x + 1;
}

#[no_inline]
fn identity(x: i32) i32 {
    return x;
}

pub fn main() i32 {
    if (compute(4) != 17) { return 1; }
    if (identity(99) != 99) { return 2; }
    // Verify each macro injected a wrapper that calls the decorated function
    if (trace_compute(4) != 1017) { return 3; }   // compute(4)+1000 = 17+1000
    if (hint_compute(3) != 20) { return 4; }        // compute(3)*2 = 10*2
    if (no_inline_identity(5) != 4) { return 5; }  // identity(5)-1 = 4
    return 0;
}
