@unsafe extern fn printf(fmt: *const i8, ...) i32;
@unsafe extern fn malloc(n: u64) *void;

struct VT { let alloc_fn: [](*void, u64)*void; }
struct Fat { let ptr: *void; let vt: *VT; }

fn my_alloc(meta: *void, n: u64) *void { let mut p: *void; @unsafe { p = malloc(n); } return p; }

istruc Wrap {
    let ptr: *void;
    let vt: *VT;
    // Calling a function-pointer struct field, through two levels of member access.
    fn go(self: *Wrap, n: u64) *void { return self.vt.alloc_fn(self.ptr, n); }
}

pub fn main() i32 {
    let mut v: VT;
    v.alloc_fn = my_alloc;
    let mut w: Wrap;
    w.ptr = (void*)0;
    w.vt  = &v;
    let mut p: *void= w.go(32u);
    @unsafe { printf("ptr=%s\n", p != (void*)0 ? "ok" : "null"); }
    if (p == (void*)0) { return 1; }
    return 0;
}
