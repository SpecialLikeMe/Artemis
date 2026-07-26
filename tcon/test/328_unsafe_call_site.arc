// Test: @unsafe is enforced at the call site, and `@unsafe { }` is the scoped opt-in.
// Regression: @unsafe was declaration-only — a safe function could call an @unsafe
// function freely, so the marker documented the trust boundary without enforcing it.
@unsafe extern fn strlen(s: *const i8) u64;

@unsafe fn raw_first(p: *i8) i8 { return p[0]; }

// A safe function may call unsafe operations inside a bounded region. The region
// keeps the obligation local instead of propagating @unsafe up to main().
fn length_of(s: *i8) i32 {
    let mut n: u64= 0;
    @unsafe { n = strlen(s); }
    return (i32)n;
}

// An @unsafe function is itself an unsafe context — no inner block needed.
@unsafe fn first_char(s: *i8) i8 {
    return raw_first(s);
}

// Nested regions must not close the outer one early.
fn nested(s: *i8) i32 {
    let mut total: i32= 0;
    @unsafe {
        total = (i32)strlen(s);
        @unsafe { total = total + (i32)raw_first(s); }
        total = total + (i32)strlen(s);
    }
    return total;
}

pub fn main() i32 {
    if (length_of("hello") != 5) { return 1; }

    let mut c: i8= 0;
    @unsafe { c = first_char("hello"); }
    if (c != 'h') { return 2; }

    // 5 + 'h'(104) + 5 = 114
    if (nested("hello") != 114) { return 3; }
    return 0;
}
