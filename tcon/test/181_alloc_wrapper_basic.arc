// Custom allocator: istruc wrapping malloc/free
@unsafe extern fn malloc(size: u64) *void;
@unsafe extern fn free(ptr: *void) void;

memstr HeapAlloc {
    let mut count: i32;

    fn __construct__(self: *HeapAlloc) void { self.count = 0; }

    fn alloc(self: *HeapAlloc, size: u64) *void {
        self.count = self.count + 1;
        return malloc(size);
    }

    fn dealloc(self: *HeapAlloc, ptr: *void) void {
        self.count = self.count - 1;
        free(ptr);
    }

    fn outstanding(self: *const HeapAlloc) i32 { return self.count; }
}

pub fn main() i32 {
    let mut a: HeapAlloc;

    let mut p: *i32= (i32*)a.alloc(sizeof(i32) * 3);
    if (p == 0) { return 1; }
    if (a.outstanding() != 1) { return 2; }

    p[0] = 10; p[1] = 20; p[2] = 30;
    let mut sum: i32= p[0] + p[1] + p[2];
    if (sum != 60) { return 3; }

    a.dealloc(p);
    if (a.outstanding() != 0) { return 4; }

    return 0;
}
