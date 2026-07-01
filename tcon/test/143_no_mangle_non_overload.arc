// Non-overloaded functions must NOT be name-mangled.
// Verify by calling them through a function pointer taken by exact name.

i32 compute(i32 x) { return x * 2; }
i32 helper(i32 a, i32 b) { return a + b; }

i32 call_via_ptr(i32(i32)* fp, i32 x) { return fp(x); }

i32 main() {
    // Direct calls work
    if (compute(5)     != 10) { return 1; }
    if (helper(3, 4)   != 7)  { return 2; }

    // Address-of non-overloaded function
    i32(i32)* fp = &compute;
    if (fp(6)          != 12) { return 3; }
    if (call_via_ptr(&compute, 7) != 14) { return 4; }

    // Overloaded functions ARE mangled — verify both overloads work independently
    return 0;
}
