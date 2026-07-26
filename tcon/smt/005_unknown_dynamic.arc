// SMT claim: dynamic access where index comes from input → verdict=UNKNOWN → runtime check injected.
// The runtime check fires only if out-of-bounds; this test exercises the safe path (check passes).
@unsafe extern fn printf(fmt: *i8, ...) i32;
@unsafe extern fn atoi(s: *i8) i32;

fn do_access(arr: *i32, idx: i32, len: i32) i32 {
    // idx is a function parameter — SMT gives it [-INF,+INF] → UNKNOWN → check injected.
    // At runtime, idx=2 < len=5 → check passes → no trap.
    if (idx < 0 || idx >= len) return -1;
    return arr[idx];
}

pub fn main() i32 {
    let mut arr: [5]i32;
    arr[0] = 1; arr[1] = 2; arr[2] = 3; arr[3] = 4; arr[4] = 5;

    // Safe access — runtime check injected by SMT but passes
    let mut v: i32= do_access(arr, 2, 5);
    if (v != 3) { printf("FAIL dynamic v=%d\n", v); return 1; }

    // In-bounds boundary accesses
    let mut v0: i32= do_access(arr, 0, 5);
    let mut v4: i32= do_access(arr, 4, 5);
    if (v0 != 1) { printf("FAIL v0=%d\n", v0); return 2; }
    if (v4 != 5) { printf("FAIL v4=%d\n", v4); return 3; }

    // Out-of-bounds guarded by explicit check → returns -1 (no trap)
    let mut oob: i32= do_access(arr, 10, 5);
    if (oob != -1) { printf("FAIL oob=%d expected -1\n", oob); return 4; }

    return 0;
}
