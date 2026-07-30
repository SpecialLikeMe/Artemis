// Tests that a memstr type constructs, allocates, and frees correctly.
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

memstr MyAlloc {
    let mut base: *void;
    let mut used: u64;
    let mut cap: u64;

    fn __construct__(self: *MyAlloc, capacity: u64) void {
        self.base = malloc(capacity);
        self.used = (u64)0;
        self.cap  = capacity;
    }

    fn alloc_bytes(self: *MyAlloc, n: u64) *void {
        if (self.used + n > self.cap) { return (void*)0; }
        let mut p: *void= (void*)((u8*)self.base + self.used);
        self.used = self.used + n;
        return p;
    }

    fn deinit(self: *MyAlloc) !void { free(self.base); }
}

pub fn main() i32 {
    let mut a: MyAlloc((u64)1024);
    if (a.base == (void*)0) { return 1; }

    // Alloc five i32s, write values
    let mut p0: *i32= (i32*)a.alloc_bytes((u64)4);
    let mut p1: *i32= (i32*)a.alloc_bytes((u64)4);
    let mut p2: *i32= (i32*)a.alloc_bytes((u64)4);
    let mut p3: *i32= (i32*)a.alloc_bytes((u64)4);
    let mut p4: *i32= (i32*)a.alloc_bytes((u64)4);
    if (p0 == (i32*)0) { return 2; }
    if (p4 == (i32*)0) { return 3; }

    (*p0) = 0;
    (*p1) = 2;
    (*p2) = 4;
    (*p3) = 6;
    (*p4) = 8;

    if ((*p0) != 0)  { return 10; }
    if ((*p1) != 2)  { return 11; }
    if ((*p2) != 4)  { return 12; }
    if ((*p3) != 6)  { return 13; }
    if ((*p4) != 8)  { return 14; }

    a.deinit();
    return 0;
}
