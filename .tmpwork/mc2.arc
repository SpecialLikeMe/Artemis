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
fn t_mmap(a: &memstr) i32 { let mut p: *i32= (i32*)a.mmap(8u); p[0]=5; let mut v: i32=p[0]; a.free((void*)p); return v; }
fn t_zero(a: &memstr) i32 { let mut z: *u8= (u8*)a.zeroed(8u); let mut v: i32=(i32)z[0]; a.free((void*)z); return v; }
pub @unsafe fn main() i32 {
    let mut s: Sys;
    printf("mmap=%d\n", t_mmap(s));
    printf("zeroed=%d\n", t_zero(s));
    printf("create=%d\n", t_create(s));
    return 0;
}
