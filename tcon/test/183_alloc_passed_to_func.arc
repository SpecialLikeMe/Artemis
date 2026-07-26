// Passing a custom allocator to functions (Zig-style allocator pattern)
@unsafe extern fn malloc(size: u64) *void;
@unsafe extern fn free(ptr: *void) void;

memstr Alloc {
    let mut total_allocs: i32;
    let mut total_frees: i32;

    fn __construct__(self: *Alloc) void { self.total_allocs = 0; self.total_frees = 0; }

    fn alloc(self: *Alloc, n: u64) *void {
        self.total_allocs = self.total_allocs + 1;
        return malloc(n);
    }

    fn dealloc(self: *Alloc, p: *void) void {
        self.total_frees = self.total_frees + 1;
        free(p);
    }
}

// Function that takes an allocator and uses it to build an array
fn sum_allocated(a: *Alloc, n: i32) i32 {
    let mut arr: *i32= (i32*)(*a).alloc((u64)(sizeof(i32)) * (u64)n);
    if (arr == 0) { return -1; }
    let mut s: i32= 0;
    for (let mut i: i32 = 0; i < n; i = i + 1) {
        arr[i] = i + 1;
        s = s + arr[i];
    }
    (*a).dealloc(arr);
    return s;
}

pub fn main() i32 {
    let mut a: Alloc;

    let mut result: i32= sum_allocated(&a, 5);  // 1+2+3+4+5 = 15
    if (result != 15) { return 1; }
    if (a.total_allocs != 1) { return 2; }
    if (a.total_frees  != 1) { return 3; }

    result = sum_allocated(&a, 3);  // 1+2+3 = 6
    if (result != 6) { return 4; }
    if (a.total_allocs != 2) { return 5; }
    if (a.total_frees  != 2) { return 6; }

    return 0;
}
