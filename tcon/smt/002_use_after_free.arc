// FAIL: SMT detects use-after-free — pointer dereferenced after free() call.
// Expected outcome: BAD (compile error emitted by smt.smt_analyze).
pub fn main() i32 {
    let mut p: *i32= (i32*)malloc(4);
    *p = 99;
    free(p);
    let mut v: i32= *p;   // SMT: p is PTR_FREED → use-after-free → compile error
    return v;
}
