// Test: ?? operator (null coalescing / orelse).
// For pointer-returning functions: null → use default.

i32* g_val = (i32*)0;
i32  g_default_val = 42;

i32* maybe_ptr(i32 give) {
    if (give) { return &g_default_val; }
    return (i32*)0;
}

i32 main() {
    // Null case: maybe_ptr(0) returns null → default pointer
    i32* p = maybe_ptr(0) ?? &g_default_val;
    if (*p != 42) { return 1; }

    // Non-null case: maybe_ptr(1) returns &g_default_val → use it
    i32* q = maybe_ptr(1) ?? (i32*)0;
    if (*q != 42) { return 2; }

    return 0;
}
