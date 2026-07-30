@unsafe extern fn printf(f: *const i8, ...) i32;
struct Pt { let x: i32; let y: i32; }
fn free_sz(comptime T: type) u64 { return (u64)@csizeof(T); }
istruc Holder {
    let n: i32;
    fn meth_sz(self: *Holder, comptime T: type) u64 { return (u64)@csizeof(T); }
}
pub fn main() i32 {
    @unsafe { printf("free fn  = %llu\n", free_sz(Pt)); }
    let mut h: Holder;
    @unsafe { printf("method   = %llu\n", h.meth_sz(Pt)); }
    return 0;
}
