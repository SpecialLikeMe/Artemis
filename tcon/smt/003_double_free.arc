// FAIL: SMT detects double-free — free() called twice on the same pointer.
// Expected outcome: BAD (compile error emitted by smt.smt_analyze).
pub fn main() i32 {
    let mut p: *i32= (i32*)malloc(4);
    *p = 7;
    free(p);
    free(p);   // SMT: p is PTR_FREED → double-free → compile error
    return 0;
}
