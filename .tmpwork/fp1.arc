@unsafe extern fn printf(fmt: *const i8, ...) i32;
struct VT { let f: [](*void, u64)*void; }
fn impl_f(meta: *void, n: u64) *void { return (void*)n; }
pub fn main() i32 {
    let mut v: VT;
    v.f = impl_f;
    // one level: call a fn-ptr field directly
    let mut p: *void= v.f((void*)0, 7u);
    @unsafe { printf("one-level=%llu\n", (u64)p); }
    if ((u64)p != 7u) { return 1; }
    return 0;
}
