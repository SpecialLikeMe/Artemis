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
fn build(a: &memstr) i32 {
    let mut p: *Pt= a.create(Pt);          // typed allocation
    p.x = 3; p.y = 4;
    let mut arr: *i32= (i32*)a.mmap(16u);
    arr[3] = 7;
    let mut z: *void= a.zeroed(8u);         // zeroed bytes
    let mut zb: *u8= (u8*)z;
    let mut sum: i32= p.x + p.y + arr[3] + (i32)zb[0];
    a.free((void*)p); a.free((void*)arr); a.free(z);
    return sum;
}
pub @unsafe fn main() i32 {
    let mut s: Sys;
    let mut r: i32= build(s);
    printf("r=%d\n", r);
    if (r != 14) { return 1; }
    return 0;
}
