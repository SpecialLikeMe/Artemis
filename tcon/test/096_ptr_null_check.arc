@unsafe extern fn malloc(size: u64) *void;
@unsafe extern fn free(ptr: *void) void;

memstr SysAlloc {
    fn mmap(self: *SysAlloc, align: usize, n: usize) !*void           { return malloc(n); }
    fn rsmap(self: *SysAlloc, p: *void, n: iofs) bool { return false; }
    fn rmap(self: *SysAlloc, align: usize, p: *void, n: iofs) !*void { return malloc((u64)n); }
    fn free(self: *SysAlloc, p: *void) !void           { free(p); }
    fn destroy(self: *SysAlloc) !void                  { }
}

pub fn main() i32 {
    let mut a: SysAlloc;
    let mut raw: *void= a.mmap((usize)sizeof(i32)) catch |e| { return 1; };
    let mut p: *i32= (i32*)raw;
    if (p == 0) { return 1; }
    *p = 77;
    let mut val: i32= *p;
    a.free(p) catch |e| { return 3; };
    if (val != 77) { return 2; }
    return 0;
}
