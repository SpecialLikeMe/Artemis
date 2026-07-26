// PASS: proc macro declarations inside a namespace inject real helper functions
// that CALL the decorated functions, proving namespace-qualified macros integrate.

namespace utils {
    fn memoize(&memstr alloc, tokenstream* input) *tokenstream attr {
        return quote {
            fn fast_fib(n: i32) i32 { return fib(n); }
        };
    }
    fn pure_fn(&memstr alloc, tokenstream* input) *tokenstream attr verify {
        return quote {
            fn pure_square(x: i32) i32 { return square(x); }
        };
    }
}

#[utils.memoize]
fn fib(n: i32) i32 {
    if (n <= 1) { return n; }
    return fib(n - 1) + fib(n - 2);
}

#[utils.pure_fn]
fn square(x: i32) i32 {
    return x * x;
}

pub fn main() i32 {
    if (fib(10) != 55)   { return 1; }
    if (square(7) != 49) { return 2; }
    // Verify namespace-qualified macros ran and injected wrappers that call decorated fns
    if (fast_fib(10) != 55)   { return 3; }
    if (pure_square(7) != 49) { return 4; }
    return 0;
}
