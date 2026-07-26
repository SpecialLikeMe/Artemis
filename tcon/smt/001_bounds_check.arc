// SMT claim: array bounds checking — constant index proven GOOD (no check); dynamic index UNKNOWN (check injected).
// This test exercises the good path of a dynamic index that is in range at runtime.
@unsafe extern fn printf(fmt: *i8, ...) i32;

let mut arr: [8]i32;

pub fn main() i32 {
    // Fill with known values (constant indices — GOOD, no runtime check)
    let mut i: i32= 0;
    while (i < 8) { arr[i] = i * 10; i = i + 1; }

    // Dynamic index that is in bounds at runtime: SMT verdict = UNKNOWN → runtime check injected.
    // The check passes (idx=3 is valid), so the program continues normally.
    let mut idx: i32= 3;
    let mut val: i32= arr[idx];
    if (val != 30) { return 1; }

    // Constant index: SMT verdict = GOOD (proven idx=7 ∈ [0,7]).
    if (arr[7] != 70) { return 2; }

    return 0;
}
