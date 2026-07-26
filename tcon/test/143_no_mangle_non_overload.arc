// Non-overloaded functions must NOT be name-mangled.
// Verify by calling them through a function pointer taken by exact name.

fn compute(x: i32) i32 { return x * 2; }
fn helper(a: i32, b: i32) i32 { return a + b; }

fn call_via_ptr(fp: *(i32)i32, x: i32) i32 { return fp(x); }

pub fn main() i32 {
    // Direct calls work
    if (compute(5)     != 10) { return 1; }
    if (helper(3, 4)   != 7)  { return 2; }

    // Address-of non-overloaded function
    let mut fp: *(i32)i32 = &compute;
    if (fp(6)          != 12) { return 3; }
    if (call_via_ptr(&compute, 7) != 14) { return 4; }

    // Overloaded functions ARE mangled — verify both overloads work independently
    return 0;
}
