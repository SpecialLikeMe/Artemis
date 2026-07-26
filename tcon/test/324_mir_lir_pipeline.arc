// Test: the --use-mir pipeline runs AST->MIR->LIR without disturbing codegen.
// Regression: mir_lower_program/lir_lower_mir were stubs returning null, so the
// pipeline produced nothing. Exercises break/continue, which need loop-target
// tracking in the lowering context to branch anywhere at all.
@unsafe extern fn printf(fmt: *i8, ...) i32;

fn sum_to(n: i32) i32 {
    let mut s: i32= 0;
    let mut i: i32= 0;
    while (i < n) {
        if (i == 3) { i = i + 1; continue; }   // skip 3
        if (i == 7) { break; }                 // stop before 7
        s = s + i;
        i = i + 1;
    }
    return s;
}

fn count_down(n: i32) i32 {
    let mut c: i32= 0;
    for (let mut i: i32 = 0; i < n; i = i + 1) {
        if (i % 2 == 0) { continue; }
        c = c + 1;
    }
    return c;
}

pub fn main() i32 {
    // 0+1+2 skipped-3 +4+5+6 then break at 7  => 18
    if (sum_to(10) != 18) { return 1; }
    // odd values below 10 => 1,3,5,7,9 => 5
    if (count_down(10) != 5) { return 2; }
    return 0;
}
