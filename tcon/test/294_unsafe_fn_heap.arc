// PASS: @unsafe fn can call malloc/free without memstr block
@unsafe extern fn malloc(size: u64) *void;
@unsafe extern fn free(ptr: *void) void;

@unsafe fn alloc_int(val: i32) *i32 {
    let mut p: *i32 = (i32*)malloc(sizeof(i32));
    if (p != (i32*)0) { *p = val; }
    return p;
}

@unsafe fn dealloc_int(p: *i32) void {
    free((void*)p);
}

pub @unsafe fn main() i32 {
    let mut p: *i32 = alloc_int(42);
    if (p == (i32*)0) { return 1; }
    let mut v: i32 = *p;
    dealloc_int(p);
    if (v != 42) { return 2; }
    return 0;
}
