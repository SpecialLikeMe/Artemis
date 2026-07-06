// SMT claim: 100% mathematical memory safety — every unsafe op either proven GOOD or guarded.
// This test exercises all three check categories: bounds, null-deref, div-zero.
extern i32 printf(i8* fmt, ...);

// Bounds: loops with statically-known ranges → all GOOD
i32 sum_array(i32* arr, i32 n) {
    i32 s = 0;
    i32 i = 0;
    while (i < n) {
        s = s + arr[i];
        i = i + 1;
    }
    return s;
}

// Null safety: address-of always non-null → deref is GOOD
i32 safe_deref(i32* p) {
    if (p == (i32*)0) return -1;
    return *p;
}

// Div safety: check before divide → denominator proven nonzero → GOOD
i32 safe_div(i32 a, i32 b) {
    if (b == 0) return 0;
    return a / b;
}

i32 main() {
    // Bounds safety
    i32 data[8];
    i32 i = 0;
    while (i < 8) { data[i] = (i + 1) * 10; i = i + 1; }
    i32 s = sum_array(data, 8);
    if (s != 360) { printf("FAIL sum=%d expected 360\n", s); return 1; }

    // Null safety: non-null pointer
    i32 val = 99;
    i32 r1 = safe_deref(&val);
    if (r1 != 99) { printf("FAIL non-null deref=%d\n", r1); return 2; }

    // Null safety: null pointer returns -1 (guarded path)
    i32 r2 = safe_deref((i32*)0);
    if (r2 != -1) { printf("FAIL null guard=%d\n", r2); return 3; }

    // Div safety: nonzero denominator
    i32 r3 = safe_div(42, 6);
    if (r3 != 7) { printf("FAIL div=%d\n", r3); return 4; }

    // Div safety: zero denominator returns 0 (guarded path)
    i32 r4 = safe_div(42, 0);
    if (r4 != 0) { printf("FAIL div_zero_guard=%d\n", r4); return 5; }

    // Nested: sum inside proven-safe loop, deref proven non-null
    i32 buf[4];
    buf[0] = 1; buf[1] = 2; buf[2] = 3; buf[3] = 4;
    i32* bptr = &buf[0];
    i32 bv = *bptr;
    if (bv != 1) { printf("FAIL buf ptr=%d\n", bv); return 6; }

    return 0;
}
