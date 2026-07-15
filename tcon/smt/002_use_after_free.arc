// FAIL: SMT detects use-after-free — pointer dereferenced after free() call.
// Expected outcome: BAD (compile error emitted by smt.smt_analyze).
i32 main() {
    i32* p = (i32*)malloc(4);
    *p = 99;
    free(p);
    i32 v = *p;   // SMT: p is PTR_FREED → use-after-free → compile error
    return v;
}
