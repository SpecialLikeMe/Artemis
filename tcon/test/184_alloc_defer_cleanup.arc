// Allocator cleanup with defer — allocation released automatically on scope exit
@unsafe extern fn malloc(size: u64) *void;
@unsafe extern fn free(ptr: *void) void;

memstr TrackedAlloc {
    let mut live: i32;
    fn __construct__(self: *TrackedAlloc) void { self.live = 0; }
    fn alloc(self: *TrackedAlloc, n: u64) *void  { self.live = self.live + 1; return malloc(n); }
    fn drop(self: *TrackedAlloc, p: *void) void { self.live = self.live - 1; free(p); }
}

// Returns the sum of 1..n using allocator-backed storage; frees on return
fn compute(a: *TrackedAlloc, n: i32) i32 {
    let mut buf: *i32= (i32*)(*a).alloc((u64)sizeof(i32) * (u64)n);
    if (buf == 0) { return -1; }
    defer (*a).drop(buf);   // guaranteed cleanup on any return path

    let mut total: i32= 0;
    for (let mut i: i32 = 0; i < n; i = i + 1) {
        buf[i] = i + 1;
        total = total + buf[i];
    }
    return total;
}

pub fn main() i32 {
    let mut ta: TrackedAlloc;

    let mut r: i32= compute(&ta, 4);   // 1+2+3+4 = 10
    if (r != 10) { return 1; }
    if (ta.live != 0) { return 2; }  // defer freed it

    r = compute(&ta, 5);       // 1+2+3+4+5 = 15
    if (r != 15) { return 3; }
    if (ta.live != 0) { return 4; }

    return 0;
}
