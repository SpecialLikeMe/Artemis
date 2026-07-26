// std.alloc.bump — Bump (linear) allocator.
// Allocates by advancing a pointer; free is a no-op; reset reclaims all memory at once.
@unsafe extern fn printf(fmt: *const i8, ...) i32;
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

namespace std {
namespace alloc {

memstr bump {
    let mut base: *void;
    let mut used: u64;
    let mut cap: u64;

    fn __construct__(self: *bump, capacity: u64) void {
        @unsafe {
            @unsafe {
                self.base = malloc(capacity);
                if (self.base == (void*)0) {
                    printf("fatal: bump allocator out of memory (requested %llu bytes)\n", capacity);
                    self.cap = 0;
                } else {
                    self.cap = capacity;
                }
                self.used = 0;
            }
        }
    }

    fn alloc_raw(self: *bump, size: u64, align: u64) *void {
        let mut offset: u64= self.used;
        // Align up: round offset up to the nearest multiple of align
        let mut rem: u64= offset % align;
        if (rem != 0) { offset = offset + (align - rem); }
        if (offset + size > self.cap) { return (void*)0; }
        let mut ptr: *void= (void*)((u8*)self.base + offset);
        self.used = offset + size;
        return ptr;
    }

    fn alloc_bytes(self: *bump, n: u64) *void { return self.alloc_raw(n, (u64)8); }

    // &memstr interface: mmap allocates n bytes, rmap is a no-op (bump allocator can't free individually)
    fn mmap(self: *bump, n: u64) *void { return self.alloc_raw(n, (u64)8); }
    fn rmap(self: *bump, p: *void, n: u64) void { }

    fn reset(self: *bump) void { self.used = 0; }

    fn deinit(self: *bump) void { free(self.base); }
}

} // alloc
} // std
