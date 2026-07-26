// SMT claim: 0% of safe programs rejected at compile time.
//
// In Rust/C++ sanitizers a dynamic index produces a hard compile error or forces
// the programmer to add explicit "unsafe" blocks.  In Artemis, the SMT verdict for
// a dynamic index is UNKNOWN — a runtime bounds check is injected and the program
// compiles.  No safe program is ever rejected simply because the SMT cannot prove
// safety statically.
//
// A "safe program" here is one that never actually performs an out-of-bounds access
// at runtime.  Every case below passes its runtime check with no abort.
//
// Patterns exercised (all compile; none abort at runtime):
//   1. Dynamic index from a function parameter — UNKNOWN, passes
//   2. Dynamic index from a computed expression — UNKNOWN, passes
//   3. Loop induction variable used as index — UNKNOWN per iter, always in-range
//   4. Pointer returned from a function, then dereferenced — UNKNOWN, passes
//   5. Index derived from runtime conditional — SMT cannot track; UNKNOWN, passes
//   6. Index derived from another array element — UNKNOWN, passes
@unsafe extern fn printf(fmt: *i8, ...) i32;

// Pattern 1: parameter as index
fn get_at(arr: *i32, idx: i32) i32 { return arr[idx]; }

// Pattern 2: computed expression as index
fn get_mid(arr: *i32, n: i32) i32 { return arr[n/2]; }

// Pattern 3: loop induction variable (caller guarantees i < size)
fn sum_loop(arr: *i32, n: i32) i32 {
    let mut s: i32= 0; let mut i: i32= 0;
    while (i < n) { s = s + arr[i]; i = i + 1; }
    return s;
}

// Pattern 4: pointer returned from helper
fn nth(arr: *i32, n: i32) *i32 { return arr + n; }

// Pattern 5: index from runtime conditional
fn conditional_index(arr: *i32, flag: i32) i32 {
    let mut idx: i32= 0;
    if (flag > 0) { idx = 1; } else { idx = 2; }
    return arr[idx];   // UNKNOWN: idx ∈ {1,2}; SMT cannot prove ∈ [0,N-1] without N
}

// Pattern 6: index from another array element
fn indirect_index(arr: *i32, indices: *i32, which: i32) i32 {
    let mut idx: i32= indices[which];   // UNKNOWN: dynamic
    return arr[idx];            // UNKNOWN: double-dynamic; safe at runtime
}

pub @unsafe fn main() i32 {
    let mut arr: [8]i32;
    arr[0]=100; arr[1]=200; arr[2]=300; arr[3]=400;
    arr[4]=500; arr[5]=600; arr[6]=700; arr[7]=800;

    // Pattern 1: in-bounds parameter — UNKNOWN compiles, check passes
    if (get_at(arr, 0) != 100) { printf("FAIL get_at 0\n"); return 1; }
    if (get_at(arr, 7) != 800) { printf("FAIL get_at 7\n"); return 2; }
    if (get_at(arr, 4) != 500) { printf("FAIL get_at 4\n"); return 3; }

    // Pattern 2: n/2 — UNKNOWN, result always in range
    if (get_mid(arr, 8) != 500) { printf("FAIL get_mid 8→4\n"); return 4; }
    if (get_mid(arr, 4) != 300) { printf("FAIL get_mid 4→2\n"); return 5; }
    if (get_mid(arr, 2) != 200) { printf("FAIL get_mid 2→1\n"); return 6; }

    // Pattern 3: loop sum — UNKNOWN per iter, all pass
    if (sum_loop(arr, 8) != 3600) { printf("FAIL sum_loop 8\n"); return 7; }
    if (sum_loop(arr, 4) != 1000) { printf("FAIL sum_loop 4\n"); return 8; }
    if (sum_loop(arr, 1) != 100)  { printf("FAIL sum_loop 1\n"); return 9; }

    // Pattern 4: pointer from helper — UNKNOWN (deref of returned ptr), passes
    let mut mid: *i32= nth(arr, 3);
    if ((*mid) != 400) { printf("FAIL nth\n"); return 10; }

    // Pattern 5: conditional index — UNKNOWN, result ∈ {arr[1], arr[2]}
    if (conditional_index(arr, 1)  != 200) { printf("FAIL cond idx pos\n"); return 11; }
    if (conditional_index(arr, -1) != 300) { printf("FAIL cond idx neg\n"); return 12; }

    // Pattern 6: indirect index from another array — UNKNOWN, in-range values used
    let mut idxs: [4]i32; idxs[0]=0; idxs[1]=3; idxs[2]=7; idxs[3]=5;
    if (indirect_index(arr, idxs, 0) != 100) { printf("FAIL indirect 0\n"); return 13; }
    if (indirect_index(arr, idxs, 1) != 400) { printf("FAIL indirect 1\n"); return 14; }
    if (indirect_index(arr, idxs, 2) != 800) { printf("FAIL indirect 2\n"); return 15; }

    return 0;
}
