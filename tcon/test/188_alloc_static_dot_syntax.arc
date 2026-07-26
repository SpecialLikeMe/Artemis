// Allocator factory via static methods using the new dot syntax
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

memstr BufAlloc {
    let mut alloc_count: i32;
    let mut free_count: i32;

    fn __construct__(self: *BufAlloc) void { self.alloc_count = 0; self.free_count = 0; }

    // Static factory: creates a default BufAlloc
    static fn make() BufAlloc {
        let mut b: BufAlloc;
        return b;
    }

    fn alloc(self: *BufAlloc, n: u64) *void  { self.alloc_count = self.alloc_count + 1; return malloc(n); }
    fn drop(self: *BufAlloc, p: *void) void { self.free_count  = self.free_count  + 1; free(p); }

    static fn overhead() i32 { return 0; }  // no metadata overhead
}

pub fn main() i32 {
    // Use new . syntax for static method calls
    let mut a: BufAlloc= BufAlloc.make();

    if (BufAlloc.overhead() != 0) { return 1; }

    let mut p1: *void= a.alloc((u64)64);
    let mut p2: *void= a.alloc((u64)128);
    if (p1 == 0 || p2 == 0) { return 2; }
    if (a.alloc_count != 2) { return 3; }

    a.drop(p1);
    a.drop(p2);
    if (a.free_count != 2) { return 4; }

    return 0;
}
