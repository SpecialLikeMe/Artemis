// PASS: memstr with the new 5-slot vtable (mmap, rsmap, rmap, free, destroy)
@unsafe extern fn malloc(size: u64) *void;
@unsafe extern fn realloc(ptr: *void, size: u64) *void;
@unsafe extern fn free(ptr: *void) void;

memstr TrackAlloc {
    let mut allocs: i32;
    let mut frees: i32;

    fn __construct__(self: *TrackAlloc) void {
        self.allocs = 0;
        self.frees  = 0;
    }

    // slot 0: mmap(meta, size) -> *void
    fn mmap(self: *TrackAlloc, n: u64) *void {
        self.allocs = self.allocs + 1;
        return malloc(n);
    }

    // slot 1: rsmap(meta, ptr, new_size) -> bool
    fn rsmap(self: *TrackAlloc, p: *void, n: iofs) bool { return false; }

    // slot 2: rmap(meta, ptr, new_size) -> *void
    fn rmap(self: *TrackAlloc, p: *void, n: iofs) *void {
        return realloc(p, (u64)n);
    }

    // slot 3: free(meta, ptr) -> void
    fn free(self: *TrackAlloc, p: *void) void {
        self.frees = self.frees + 1;
        free(p);
    }

    // slot 4: destroy(meta) -> void
    fn destroy(self: *TrackAlloc) void { }
}

pub fn main() i32 {
    let mut a: TrackAlloc();

    let mut p: *i32 = (i32*)a.mmap(sizeof(i32) * 4);
    if (p == (i32*)0) { return 1; }
    p[0] = 10; p[1] = 20; p[2] = 30; p[3] = 40;
    if (p[0] + p[1] + p[2] + p[3] != 100) { return 2; }

    let mut q: *i32 = (i32*)a.mmap(sizeof(i32) * 2);
    if (q == (i32*)0) { return 3; }
    q[0] = 1; q[1] = 2;

    a.free(p);
    a.free(q);

    if (a.allocs != 2) { return 4; }
    if (a.frees  != 2) { return 5; }

    a.destroy();
    return 0;
}
