// PASS: proc macro declared with 'attr verify' tag injects code.
// Macros inject wrappers that call the decorated functions,
// proving that verify-tagged macros produce real, integrated output.

fn bounds_check(&memstr alloc, tokenstream* input) *tokenstream attr verify {
    return quote {
        fn safe_div_checked(a: i32, b: i32) i32 {
            if (b == 0) { return -1; }
            return safe_div(a, b);
        }
    };
}

fn non_null_args(&memstr alloc, tokenstream* input) *tokenstream attr verify {
    return quote {
        fn strlen_checked(s: *i8) i32 {
            if (s == (i8*)0) { return -1; }
            return strlen_safe(s);
        }
    };
}

#[bounds_check]
fn safe_div(a: i32, b: i32) i32 {
    if (b == 0) { return 0; }
    return a / b;
}

#[non_null_args]
fn strlen_safe(s: *i8) i32 {
    if (s == (i8*)0) { return 0; }
    let mut n: i32= 0;
    while (s[n] != 0) { n = n + 1; }
    return n;
}

pub fn main() i32 {
    if (safe_div(10, 2) != 5)  { return 1; }
    if (safe_div(7, 0) != 0)   { return 2; }
    if (strlen_safe("hello") != 5) { return 3; }
    if (strlen_safe((i8*)0) != 0)  { return 4; }
    // Verify injected wrappers call original functions correctly
    if (safe_div_checked(10, 2) != 5)    { return 5; }
    if (safe_div_checked(7, 0) != -1)    { return 6; }  // wrapper returns -1, not 0
    if (strlen_checked("hi") != 2)       { return 7; }
    if (strlen_checked((i8*)0) != -1)    { return 8; }  // wrapper returns -1
    return 0;
}
