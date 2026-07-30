// PASS: memstr deinit() is accepted as alias for destroy vtable slot.
// Also: &memstr fat-pointer dispatch works when passed to a function.
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

memstr Heap {
    fn mmap(self: *Heap, align: usize, size: usize) !*void    { return malloc(size); }
    fn rsmap(self: *Heap, p: *void, n: iofs) bool { return false; }
    fn rmap(self: *Heap, align: usize, p: *void, n: iofs) !*void { return malloc((u64)n); }
    fn free(self: *Heap, p: *void) !void      { free(p); }
    fn deinit(self: *Heap) !void              { }  // deinit accepted for destroy slot
}

fn alloc_bytes(ms: &memstr, n: u64) *void { return ms.mmap((usize)n) catch |e| { return (void*)0; }; }
fn free_bytes(ms: &memstr, p: *void) void { ms.free(p) catch |e| { }; }
fn teardown(ms: &memstr) void             { ms.deinit() catch |e| { }; }

pub fn main() i32 {
    let mut heap: Heap;

    // Direct method calls on concrete type
    let raw: *void = heap.mmap((usize)16) catch |e| { return 1; };
    if (raw == (void*)0) { return 1; }
    let p: *i32 = (i32*)raw;
    p[0] = 77;
    if (p[0] != 77) { return 2; }
    heap.free(raw) catch |e| { return 5; };

    // Via fat pointer dispatch (pass concrete type to &memstr parameter)
    let raw2: *void = alloc_bytes(heap, (u64)8);
    if (raw2 == (void*)0) { return 3; }
    let q: *i64 = (i64*)raw2;
    q[0] = (i64)12345;
    if (q[0] != (i64)12345) { return 4; }
    free_bytes(heap, raw2);

    // deinit through fat pointer dispatch
    teardown(heap);

    return 0;
}
