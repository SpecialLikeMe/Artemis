// Test: std.debug — std.debug.poison/std.debug.is_poisoned, std.debug.assert (non-panic path), std.debug.null_check
extern std.debug;
extern void* malloc(u64 n);
extern void  free(void* p);
extern i32   printf(i8* fmt, ...);

memstr SysAlloc {
    void* mmap(SysAlloc* self, u64 n)         { return malloc(n); }
    void  rmap(SysAlloc* self, void* p, u64 n) { free(p); }
}

// Zero a byte buffer — kept in a helper to avoid the pre-existing
// memstr-instance + loop-in-same-function IR crash.
void zero_buf(u8* b, i32 n) {
    i32 i = 0;
    while (i < n) { b[i] = 0; i = i + 1; }
}

i32 main() {
    SysAlloc sa;

    // std.debug.poison fills memory with a pattern
    void* p = sa.mmap((u64)16);
    if (p == (void*)0) { return 1; }
    std.debug.poison(p, (u64)16);
    if (!std.debug.is_poisoned(p, (u64)16)) {
        printf("FAIL std.debug.is_poisoned after std.debug.poison\n");
        sa.rmap(p, (u64)16);
        return 2;
    }

    // Writing clean data makes it not poisoned
    zero_buf((u8*)p, 16);
    if (std.debug.is_poisoned(p, (u64)16)) {
        printf("FAIL std.debug.is_poisoned after clear\n");
        sa.rmap(p, (u64)16);
        return 3;
    }

    sa.rmap(p, (u64)16);

    // std.debug.assert with true condition is a no-op (doesn't panic)
    std.debug.assert(true, "should not panic");

    // std.debug.null_check with non-null pointer is a no-op
    void* q = sa.mmap((u64)1);
    std.debug.null_check(q, "017_debug");
    sa.rmap(q, (u64)1);

    return 0;
}
