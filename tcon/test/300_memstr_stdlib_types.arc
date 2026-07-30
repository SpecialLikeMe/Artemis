// PASS: __vtable__ and memstr are compiler builtins — available with no include.

@unsafe extern fn malloc(size: u64) *void;
@unsafe extern fn free(ptr: *void) void;

memstr HeapAlloc {
    fn mmap(self: *HeapAlloc, align: usize, n: usize) !*void    { return malloc(n); }
    fn rsmap(self: *HeapAlloc, p: *void, n: iofs) bool { return false; }
    fn rmap(self: *HeapAlloc, align: usize, p: *void, n: iofs) !*void { return malloc(n); }
    fn free(self: *HeapAlloc, p: *void) !void   { free(p); }
    fn destroy(self: *HeapAlloc) !void          { }
}

pub fn main() i32 {
    // memstr and __vtable__ types are available
    let mut vt_size: usize = @csizeof(__vtable__);
    let mut ms_size: usize = @csizeof(memstr);
    // __vtable__ = 5 ptrs = 40 bytes on 64-bit
    if (vt_size != (usize)40) { return 1; }
    // memstr = 2 ptrs = 16 bytes on 64-bit
    if (ms_size != (usize)16) { return 2; }
    // Basic allocation still works
    let mut a: HeapAlloc;
    let mut raw: *void = a.mmap((usize)sizeof(i32)) catch |e| { return 3; };
    let mut p: *i32 = (i32*)raw;
    if (p == (i32*)0) { return 3; }
    *p = 99;
    if (*p != 99) { return 4; }
    a.free((void*)p) catch |e| { return 5; };
    return 0;
}
