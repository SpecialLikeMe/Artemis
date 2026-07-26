// memstr declaration: the compiler accepts the memstr keyword with class-body syntax.
// A memstr type is a first-class allocator type that is valid for &memstr parameters.
// The vtable now has 5 slots: mmap, rsmap, rmap, free, destroy.
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

// memstr with class-body syntax (methods + fields)
memstr BumpAlloc {
    let mut base: *void;
    let mut used: u64;
    let mut cap: u64;

    fn __construct__(self: *BumpAlloc, capacity: u64) void {
        self.base = malloc(capacity);
        self.used = 0;
        self.cap  = capacity;
    }

    // vtable slot 0: mmap(meta, size) -> *void
    fn mmap(self: *BumpAlloc, n: u64) *void {
        let mut aligned: u64= (n + 7) & ~(u64)7;
        if (self.used + aligned > self.cap) { return (void*)0; }
        let mut p: *void= (void*)((u8*)self.base + self.used);
        self.used = self.used + aligned;
        return p;
    }

    // vtable slot 1: rsmap(meta, ptr, new_size) -> bool (in-place resize not supported)
    fn rsmap(self: *BumpAlloc, ptr: *void, new_size: iofs) bool {
        return false;
    }

    // vtable slot 2: rmap(meta, ptr, new_size) -> *void (fall back to mmap)
    fn rmap(self: *BumpAlloc, ptr: *void, new_size: iofs) *void {
        return self.mmap((u64)new_size);
    }

    // vtable slot 3: free(meta, ptr) -> void (bump allocator doesn't free individually)
    fn free(self: *BumpAlloc, ptr: *void) void { }

    // vtable slot 4: destroy(meta) -> void
    fn destroy(self: *BumpAlloc) void { free(self.base); }
}

pub fn main() i32 {
    let mut a: BumpAlloc(1024);
    if (a.base == (void*)0) { return 1; }

    let mut p: *i32= (i32*)a.mmap(sizeof(i32) * 4);
    if (p == (i32*)0) { return 2; }

    p[0] = 10; p[1] = 20; p[2] = 30; p[3] = 40;
    let mut sum: i32= p[0] + p[1] + p[2] + p[3];
    if (sum != 100) { return 3; }

    a.destroy();
    return 0;
}
