@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn printf(f: *const i8, ...) i32;

@unsafe fn ok_alloc(align: u64, meta: *void, n: u64) !*void {
    let mut p: *void= malloc(n);
    if (p == (void*)0) { return error.OutOfMemory; }
    return p;
}
@unsafe fn bad_alloc(align: u64, meta: *void, n: u64) !*void {
    return error.OutOfMemory;
}

struct VT { let mmap: [](u64, *void, u64)!*void; }

pub @unsafe fn main() i32 {
    let mut v: VT;
    v.mmap = ok_alloc;
    // call an error-union-returning function through a pointer field
    let mut p: *void= v.mmap(8u, (void*)0, 16u) catch |e| { printf("caught\n"); return 1; };
    printf("ok ptr=%s\n", p != (void*)0 ? "yes" : "no");
    v.mmap = bad_alloc;
    let mut q: *void= v.mmap(8u, (void*)0, 16u) catch |e| { printf("err path ok\n"); return 0; };
    printf("BAD: should not reach\n");
    return 2;
}
