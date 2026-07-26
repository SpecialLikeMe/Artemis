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
    let mut p: *i32= (i32*)a.mmap(sizeof(i32));
    if (p == 0) { return 1; }
    *p = 77;
    let mut val: i32= *p;
    a.free(p);
    if (val != 77) { return 2; }
    return 0;
}
