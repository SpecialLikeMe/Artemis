// FAIL: a value-carrying error union that falls off the end is a missing return.
// Regression: `!*void` was classified as `!void` because the payload's primitive is
// void_t, ignoring pointer_depth. The function emitted a bare `ret i32 0` out of a
// { i32, ptr } signature; when that got past the verifier it handed the caller a
// success value with an undef payload, which passes every error check.
@unsafe extern fn malloc(n: u64) *void;

fn grab(n: usize) !*void {
    let mut p: *void= malloc((u64)n);   // no return
}

pub fn main() i32 {
    let mut q: *void= grab((usize)8) catch |e| { return 1; };
    if (q == (void*)0) { return 2; }
    return 0;
}
