// std.alloc.ring — Ring/circular buffer allocator.
// Allocates in a circular fashion; oldest allocation is overwritten when buffer wraps.
// Suitable for temporary scratch buffers in tight loops.
@unsafe extern fn printf(fmt: *const i8, ...) i32;
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

namespace std {
namespace alloc {

memstr ring {
    let mut base: *void;
    let mut cap: u64;
    let mut head: u64;

    fn __construct__(self: *ring, capacity: u64) void {
        @unsafe {
            @unsafe {
                self.base = malloc(capacity);
                if (self.base == (void*)0) {
                    printf("fatal: ring allocator out of memory (requested %llu bytes)\n", capacity);
                    self.cap = 0;
                } else {
                    self.cap = capacity;
                }
                self.head = 0;
            }
        }
    }

    fn alloc_bytes(self: *ring, n: u64) *void {
        let mut aligned: u64= (n + 7) & ~(u64)7;
        if (aligned > self.cap) { return (void*)0; }
        if (self.head + aligned > self.cap) { self.head = 0; }
        let mut p: *void= (void*)((u8*)self.base + self.head);
        self.head = self.head + aligned;
        return p;
    }

    fn reset(self: *ring) void { self.head = 0; }

    fn deinit(self: *ring) !void { free(self.base); }
}

} // alloc
} // std
