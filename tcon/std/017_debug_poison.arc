// Test: std.debug — std.debug.poison/std.debug.is_poisoned, std.debug.assert (non-std.debug.panic path), std.debug.null_check
extern std.debug;
extern void* malloc(u64 n);
extern void  free(void* p);
extern i32   printf(i8* fmt, ...);

i32 main() {
    // std.debug.poison fills memory with a pattern
    void* p = malloc((u64)16);
    if (p == (void*)0) { return 1; }
    std.debug.poison(p, (u64)16);
    if (!std.debug.is_poisoned(p, (u64)16)) { printf("FAIL std.debug.is_poisoned after std.debug.poison\n"); free(p); return 2; }

    // Writing clean data makes it not poisoned
    u8* b = (u8*)p;
    for (i32 i = 0; i < 16; i = i + 1) { b[i] = 0; }
    if (std.debug.is_poisoned(p, (u64)16)) { printf("FAIL std.debug.is_poisoned after clear\n"); free(p); return 3; }

    free(p);

    // std.debug.assert with true condition is a no-op (doesn't std.debug.panic)
    std.debug.assert(true, "should not std.debug.panic");

    // std.debug.null_check with non-null pointer is a no-op
    void* q = malloc((u64)1);
    std.debug.null_check(q, "017_debug");
    free(q);

    return 0;
}
