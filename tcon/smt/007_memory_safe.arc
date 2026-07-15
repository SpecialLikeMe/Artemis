// SMT claim: 100% mathematical memory safety — every safety-critical operation is either
// proven GOOD (no check) or guarded by an injected runtime check (UNKNOWN).
// No unsafe operation can execute silently: it either cannot happen (GOOD proof) or
// the runtime guard aborts the process before the UB occurs.
//
// This test exercises ALL four check categories provided by the SMT and verifies
// that both the safe and the guarded paths produce the correct observable result:
//
//   Category A — Array bounds:   constant index → GOOD; dynamic index → UNKNOWN + check
//   Category B — Null dereference: address-of → GOOD; explicit guard → safe null path
//   Category C — Division/modulo: constant divisor → GOOD; guarded divisor → safe zero path
//   Category D — Pointer lifetime: stack alloc, write, read; SMT tracks ptr state as VALID
//                                  (BAD paths — free/use, double-free — are in 002 and 003)
extern i32 printf(i8* fmt, ...);

// ---- Category A: Array bounds ----

// Constant-index access: SMT proves each literal in [0, N-1] → GOOD, no check.
i32 const_sum(i32* arr) {
    return arr[0] + arr[1] + arr[2] + arr[3];
}

// Dynamic-index access: SMT gives UNKNOWN → injects icmp uge / br abort check.
// Caller guarantees idx < 4; check passes; result is correct.
i32 dyn_get(i32* arr, i32 idx) {
    return arr[idx];
}

// ---- Category B: Null dereference ----

// Address-of is always non-null; SMT verdict = GOOD for subsequent deref.
i32 deref_local() {
    i32 x = 55;
    i32* p = &x;
    return (*p);   // GOOD: p = &x → abs_ptr{non_null}
}

// Explicit null-guard before deref — caller can pass null; returns sentinel on null.
i32 safe_deref(i32* p) {
    if (p == (i32*)0) { return -1; }
    return (*p);   // GOOD: SMT knows p ≠ null after the guard
}

// Returns pointer to one of two stack slots based on flag — both are non-null.
i32* pick(i32* a, i32* b, i32 flag) {
    if (flag != 0) { return a; }
    return b;
}

// ---- Category C: Division and modulo ----

// Constant nonzero divisor: interval [N,N] with N≠0 → GOOD.
i32 const_div() {
    i32 a = 100 / 4;    // GOOD: 4 is provably nonzero
    i32 b = 77  % 10;   // GOOD: 10 is provably nonzero
    return a + b;       // 25 + 7 = 32
}

// Guarded divisor: after the zero-check, SMT knows b ≠ 0 → GOOD.
i32 guarded_div(i32 a, i32 b) {
    if (b == 0) { return 0; }
    return a / b;   // GOOD: b proved nonzero by the if-guard
}

// ---- Category D: Pointer lifetime (stack-only) ----
// Alloc on stack → write via pointer → read via pointer: all states VALID.
i32 lifetime_stack() {
    i32 buf[4];
    i32* p = &buf[0];
    (*p)       = 10;
    (*(p+1))   = 20;
    (*(p+2))   = 30;
    (*(p+3))   = 40;
    return (*p) + buf[1] + buf[2] + buf[3];   // 10+20+30+40 = 100
}

// ---- main: exercise every safe path ----
i32 main() {
    // A1: constant-index access → GOOD
    i32 arr[4]; arr[0]=10; arr[1]=20; arr[2]=30; arr[3]=40;
    i32 s = const_sum(arr);
    if (s != 100) { printf("FAIL const_sum=%d\n", s); return 1; }

    // A2: dynamic-index access (UNKNOWN → check injected, passes)
    if (dyn_get(arr, 0) != 10) { printf("FAIL dyn idx0\n"); return 2; }
    if (dyn_get(arr, 3) != 40) { printf("FAIL dyn idx3\n"); return 3; }

    // B1: address-of always non-null → GOOD
    if (deref_local() != 55) { printf("FAIL deref_local\n"); return 4; }

    // B2: null guard — non-null path
    i32 v = 77;
    if (safe_deref(&v) != 77) { printf("FAIL safe_deref nonnull\n"); return 5; }

    // B2: null guard — null path returns sentinel (-1), no abort
    if (safe_deref((i32*)0) != -1) { printf("FAIL safe_deref null\n"); return 6; }

    // B3: pick — both branches return non-null address-of
    i32 aa = 11; i32 bb = 22;
    i32* chosen = pick(&aa, &bb, 1);
    if ((*chosen) != 11) { printf("FAIL pick true\n"); return 7; }
    chosen = pick(&aa, &bb, 0);
    if ((*chosen) != 22) { printf("FAIL pick false\n"); return 8; }

    // C1: constant divisor → GOOD
    if (const_div() != 32) { printf("FAIL const_div\n"); return 9; }

    // C2: guarded divisor — nonzero path
    if (guarded_div(30, 6) != 5) { printf("FAIL guarded_div 30/6\n"); return 10; }

    // C2: guarded divisor — zero path returns 0 (no UB, no abort)
    if (guarded_div(99, 0) != 0) { printf("FAIL guarded_div zero\n"); return 11; }

    // D: stack lifetime — all pointer states VALID throughout
    if (lifetime_stack() != 100) { printf("FAIL lifetime_stack\n"); return 12; }

    return 0;
}
