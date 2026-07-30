// FAIL: a constant index outside a fixed array is rejected by the SMT pass that runs
// on LIR (AST -> MIR -> LIR -> SMT).
//
// This is caught in the lowered form, not the source form: the store lowers to a GEP
// carrying the array and the index, and the alloca carries the declared extent, so the
// check has both numbers in one place.
//
// Regression: MIR lowering used to drop subscripts entirely — `a[i] = v` lowered to a
// store to nothing and `a[i]` read as the constant 0 — so nothing downstream could see
// the access at all.
pub fn main() i32 {
    let mut a: [4]i32;
    a[0] = 1;
    a[7] = 9;      // out of range
    return a[0];
}
