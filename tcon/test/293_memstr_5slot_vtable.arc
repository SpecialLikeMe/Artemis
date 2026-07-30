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
    fn mmap(self: *TrackAlloc, align: usize, n: usize) !*void {
        self.allocs = self.allocs + 1;
        return malloc(n);
    }

    // slot 1: rsmap(meta, ptr, new_size) -> bool
    fn rsmap(self: *TrackAlloc, p: *void, n: iofs) bool { return false; }

    // slot 2: rmap(meta, ptr, new_size) -> *void
    fn rmap(self: *TrackAlloc, align: usize, p: *void, n: iofs) !*void {
        return realloc(p, (u64)n);
    }

    // slot 3: free(meta, ptr) -> void
    fn free(self: *TrackAlloc, p: *void) !void {
        self.frees = self.frees + 1;
        free(p);
    }

    // slot 4: destroy(meta) -> void
    fn destroy(self: *TrackAlloc) !void { }
}

pub fn main() i32 {
    let mut a: TrackAlloc();

    let mut praw: *void= a.mmap((usize)(sizeof(i32) * 4)) catch |e| { return 1; };
    let mut p: *i32 = (i32*)praw;
    if (p == (i32*)0) { return 1; }
    p[0] = 10; p[1] = 20; p[2] = 30; p[3] = 40;
    if (p[0] + p[1] + p[2] + p[3] != 100) { return 2; }

    let mut qraw: *void= a.mmap((usize)(sizeof(i32) * 2)) catch |e| { return 1; };
    let mut q: *i32 = (i32*)qraw;
    if (q == (i32*)0) { return 3; }
    q[0] = 1; q[1] = 2;

    a.free(p) catch |e| { return 8; };
    a.free(q) catch |e| { return 8; };

    if (a.allocs != 2) { return 4; }
    if (a.frees  != 2) { return 5; }

    a.destroy() catch |e| { return 9; };
    return 0;
}
