// &memstr as a parameter type: the compiler accepts memstr-typed parameters.
// The allocator is backed by an istruc passed by pointer.
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

memstr SimpleAlloc {
    let mut count: i32;
    fn __construct__(self: *SimpleAlloc) void { self.count = 0; }
    fn alloc(self: *SimpleAlloc, n: u64) *void  { self.count = self.count + 1; return malloc(n); }
    fn drop(self: *SimpleAlloc, p: *void) void { self.count = self.count - 1; free(p); }
}

// Accept allocator by pointer and use it
fn sum_with_alloc(a: *SimpleAlloc, n: i32) i32 {
    let mut arr: *i32= (i32*)(*a).alloc((u64)sizeof(i32) * (u64)n);
    if (arr == 0) { return -1; }
    let mut s: i32= 0;
    for (let mut i: i32 = 0; i < n; i = i + 1) { arr[i] = i + 1; s = s + arr[i]; }
    (*a).drop(arr);
    return s;
}

pub fn main() i32 {
    let mut a: SimpleAlloc;
    if (sum_with_alloc(&a, 5) != 15) { return 1; }  // 1+2+3+4+5
    if (sum_with_alloc(&a, 4) != 10) { return 2; }  // 1+2+3+4
    if (a.count != 0) { return 3; }                 // all freed
    return 0;
}
