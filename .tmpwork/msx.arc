@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;
@unsafe extern fn printf(f: *const i8, ...) i32;

memstr Sys {
    fn mmap(self: *Sys, n: u64) *void { return malloc(n); }
    fn rsmap(self: *Sys, p: *void, n: iofs) bool { return false; }
    fn rmap(self: *Sys, p: *void, n: iofs) *void { return malloc((u64)n); }
    fn free(self: *Sys, p: *void) void { free(p); }
    fn destroy(self: *Sys) void { }
}

fn use_alloc(a: &memstr) i32 {
    let mut p: *i32= (i32*)a.mmap(16u);
    if (p == (i32*)0) { return -1; }
    p[0] = 99;
    let mut v: i32= p[0];
    a.free((void*)p);
    return v;
}

pub @unsafe fn main() i32 {
    let mut s: Sys;
    let mut r: i32= use_alloc(s);
    printf("r=%d\n", r);
    if (r != 99) { return 1; }
    return 0;
}
