// Test: ?? operator (null coalescing / orelse).
// For pointer-returning functions: null → use default.

let mut g_val: *i32= (i32*)0;
let mut g_default_val: i32= 42;

fn maybe_ptr(give: i32) *i32 {
    if (give) { return &g_default_val; }
    return (i32*)0;
}

pub fn main() i32 {
    // Null case: maybe_ptr(0) returns null → default pointer
    let mut p: *i32= maybe_ptr(0) ?? &g_default_val;
    if (*p != 42) { return 1; }

    // Non-null case: maybe_ptr(1) returns &g_default_val → use it
    let mut q: *i32= maybe_ptr(1) ?? (i32*)0;
    if (*q != 42) { return 2; }

    return 0;
}
