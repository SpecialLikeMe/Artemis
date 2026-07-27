@unsafe extern fn printf(fmt: *const i8, ...) i32;
struct VT { let f: [](*void, u64)*void; }
fn impl_f(meta: *void, n: u64) *void { return (void*)n; }
pub fn main() i32 {
    let mut v: VT;
    v.f = impl_f;
    let mut vp: *VT= &v;
    // two levels: through a pointer
    let mut p: *void= vp.f((void*)0, 9u);
    @unsafe { printf("thru-ptr=%llu\n", (u64)p); }
    if ((u64)p != 9u) { return 1; }
    return 0;
}
