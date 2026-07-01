// Test: std.debug — debug::poison/debug::is_poisoned, debug::assert (non-debug::panic path), debug::null_check
extern std.debug;
extern void* malloc(u64 n);
extern void  free(void* p);
extern i32   printf(i8* fmt, ...);

i32 main() {
    // debug::poison fills memory with a pattern
    void* p = malloc((u64)16);
    if (p == (void*)0) { return 1; }
    debug::poison(p, (u64)16);
    if (!debug::is_poisoned(p, (u64)16)) { printf("FAIL debug::is_poisoned after debug::poison\n"); free(p); return 2; }

    // Writing clean data makes it not poisoned
    u8* b = (u8*)p;
    for (i32 i = 0; i < 16; i = i + 1) { b[i] = 0; }
    if (debug::is_poisoned(p, (u64)16)) { printf("FAIL debug::is_poisoned after clear\n"); free(p); return 3; }

    free(p);

    // debug::assert with true condition is a no-op (doesn't debug::panic)
    debug::assert(true, "should not debug::panic");

    // debug::null_check with non-null pointer is a no-op
    void* q = malloc((u64)1);
    debug::null_check(q, "017_debug");
    free(q);

    return 0;
}
