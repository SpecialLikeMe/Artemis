// Test: std.debug — std.debug.poison/std.debug.is_poisoned, std.debug.assert (non-panic path), std.debug.null_check
extern  std.debug;
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;
@unsafe extern fn printf(fmt: *i8, ...) i32;

memstr SysAlloc {
    fn mmap(self: *SysAlloc, n: u64) *void         { return malloc(n); }
    fn rmap(self: *SysAlloc, p: *void, n: u64) void { free(p); }
}

// Zero a byte buffer — kept in a helper to avoid the pre-existing
// memstr-instance + loop-in-same-function IR crash.
fn zero_buf(b: *u8, n: i32) void {
    let mut i: i32= 0;
    while (i < n) { b[i] = 0; i = i + 1; }
}

pub @unsafe fn main() i32 {
    let mut sa: SysAlloc;

    // std.debug.poison fills memory with a pattern
    let mut p: *void= sa.mmap((u64)16);
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
    let mut q: *void= sa.mmap((u64)1);
    std.debug.null_check(q, "017_debug");
    sa.rmap(q, (u64)1);

    return 0;
}
