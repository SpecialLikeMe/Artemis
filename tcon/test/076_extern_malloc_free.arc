@unsafe extern fn malloc(size: u64) *void;
@unsafe extern fn free(ptr: *void) void;

memstr SysAlloc {
    fn mmap(self: *SysAlloc, n: u64) *void           { return malloc(n); }
    fn rsmap(self: *SysAlloc, p: *void, n: iofs) bool { return false; }
    fn rmap(self: *SysAlloc, p: *void, n: iofs) *void { return malloc((u64)n); }
    fn free(self: *SysAlloc, p: *void) void           { free(p); }
    fn destroy(self: *SysAlloc) void                  { }
}

pub fn main() i32 {
    let mut a: SysAlloc;
    let mut p: *i32= (i32*)a.mmap(sizeof(i32) * 4);
    if (p == 0) { return 1; }
    p[0] = 10;
    p[1] = 20;
    p[2] = 30;
    p[3] = 40;
    let mut sum: i32= p[0] + p[1] + p[2] + p[3];
    a.free(p);
    if (sum != 100) { return 2; }
    return 0;
}
