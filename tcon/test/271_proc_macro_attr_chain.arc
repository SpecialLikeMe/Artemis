// PASS: attr proc macros chained on multiple functions.
// Each macro injects a wrapper that calls the decorated function,
// proving the injected code interacts with the decorated item.

fn deprecated(&memstr alloc, tokenstream* input) *tokenstream attr {
    return quote {
        fn compat_old_add(a: i32, b: i32) i32 {
            return old_add(a, b) + 1000;
        }
    };
}

fn experimental(&memstr alloc, tokenstream* input) *tokenstream attr verify {
    return quote {
        fn beta_new_add(a: i32, b: i32) i32 {
            return new_add(a, b) - 1;
        }
    };
}

fn hot_path(&memstr alloc, tokenstream* input) *tokenstream attr {
    return quote {
        fn cached_fast_mul(a: i32, b: i32) i32 {
            return fast_mul(a, b);
        }
    };
}

#[deprecated]
fn old_add(a: i32, b: i32) i32 { return a + b; }

#[experimental]
fn new_add(a: i32, b: i32) i32 { return a + b; }

#[hot_path]
fn fast_mul(a: i32, b: i32) i32 { return a * b; }

pub fn main() i32 {
    if (old_add(1, 2) != 3)    { return 1; }
    if (new_add(10, 20) != 30) { return 2; }
    if (fast_mul(6, 7) != 42)  { return 3; }
    // Verify injected wrappers call the decorated functions
    if (compat_old_add(1, 2) != 1003) { return 4; }  // old_add(1,2)+1000
    if (beta_new_add(10, 20) != 29)   { return 5; }  // new_add(10,20)-1
    if (cached_fast_mul(6, 7) != 42)  { return 6; }  // fast_mul(6,7)
    return 0;
}
