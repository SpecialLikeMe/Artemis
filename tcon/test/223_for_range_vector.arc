// PASS: range-based for loop works over a runtime-length std.vector via .length field.
extern std.vector;

@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

// Minimal inline allocator so the test has no external deps beyond malloc/free.
memstr HeapBump {
    let mut base: *void;
    let mut used: u64;
    let mut cap: u64;
    fn __construct__(self: *HeapBump, capacity: u64) void {
        self.base = malloc(capacity);
        self.used = 0;
        self.cap  = capacity;
    }
    fn mmap(self: *HeapBump, align: usize, n: usize) !*void {
        let mut aligned: u64= (n + 7) & ~(u64)7;
        if (self.used + aligned > self.cap) { return (void*)0; }
        let mut p: *void= (void*)((u8*)self.base + self.used);
        self.used = self.used + aligned;
        return p;
    }
    fn rmap(self: *HeapBump, align: usize, p: *void, n: iofs) !*void { return error.Unsupported; }
    fn deinit(self: *HeapBump) !void { free(self.base); }
}

pub fn main() i32 {
    let mut bump: HeapBump(8192);

    let mut v: std.vector<i32>(4, bump);
    v.push(10, bump);
    v.push(20, bump);
    v.push(30, bump);

    let mut sum: i32= 0;
    for (let x: i32 : v) {
        sum = sum + x;
    }
    if (sum != 60) { return 1; }

    bump.deinit();
    return 0;
}
