@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;
@unsafe extern fn printf(f: *const i8, ...) i32;
struct Pt { let x: i32; let y: i32; }
memstr Sys {
    fn mmap(self: *Sys, n: u64) *void { return malloc(n); }
    fn rsmap(self: *Sys, p: *void, n: iofs) bool { return false; }
    fn rmap(self: *Sys, p: *void, n: iofs) *void { return malloc((u64)n); }
    fn free(self: *Sys, p: *void) void { free(p); }
    fn destroy(self: *Sys) void { }
}
fn t_create(a: &memstr) i32 {
    let mut p: *Pt= a.create(Pt);
    if (p == (Pt*)0) { return -1; }
    p.x = 3; p.y = 4;
    let mut v: i32= p.x + p.y;
    a.free((void*)p);
    return v;
}
pub @unsafe fn main() i32 {
    let mut s: Sys;
    let mut r: i32= t_create(s);
    printf("create=%d\n", r);
    return 0;
}
