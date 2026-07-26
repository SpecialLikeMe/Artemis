// PASS: attribute proc macro — declared as attr function, applied via #[name]
// The macro is a pass-through (returns input unchanged); the decorated function
// compiles and runs normally.

fn log_calls(&memstr alloc, tokenstream* input) *tokenstream attr {
    return input;
}

fn mark_pure(&memstr alloc, tokenstream* input) *tokenstream attr verify {
    return input;
}

#[log_calls]
fn add(a: i32, b: i32) i32 {
    return a + b;
}

#[mark_pure]
fn mul(a: i32, b: i32) i32 {
    return a * b;
}

pub fn main() i32 {
    if (add(2, 3) != 5)  { return 1; }
    if (mul(4, 5) != 20) { return 2; }
    return 0;
}
