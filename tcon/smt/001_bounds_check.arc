// SMT claim: array bounds checking — constant index proven GOOD (no check); dynamic index UNKNOWN (check injected).
// This test exercises the good path of a dynamic index that is in range at runtime.
extern i32 printf(i8* fmt, ...);

i32 arr[8];

i32 main() {
    // Fill with known values (constant indices — GOOD, no runtime check)
    i32 i = 0;
    while (i < 8) { arr[i] = i * 10; i = i + 1; }

    // Dynamic index that is in bounds at runtime: SMT verdict = UNKNOWN → runtime check injected.
    // The check passes (idx=3 is valid), so the program continues normally.
    i32 idx = 3;
    i32 val = arr[idx];
    if (val != 30) { return 1; }

    // Constant index: SMT verdict = GOOD (proven idx=7 ∈ [0,7]).
    if (arr[7] != 70) { return 2; }

    return 0;
}
