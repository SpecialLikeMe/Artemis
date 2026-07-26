// std.alloc.arena — Region/arena allocator with sub-regions.
// Allocates a large block upfront; sub-arenas can checkpoint and rollback.
@unsafe extern fn printf(fmt: *const i8, ...) i32;
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

namespace std {
namespace alloc {

memstr arena {
    let mut base: *void;
    let mut used: u64;
    let mut cap: u64;
    let mut checkpoint: u64;

    fn __construct__(self: *arena, capacity: u64) void {
        self.base = malloc(capacity);
        if (self.base == (void*)0) {
            printf("fatal: arena allocator out of memory (requested %llu bytes)\n", capacity);
            self.cap = 0;
        } else {
            self.cap = capacity;
        }
        self.used       = 0;
        self.checkpoint = 0;
    }

    fn alloc_bytes(self: *arena, n: u64) *void {
        let mut aligned: u64= (n + 7) & ~(u64)7;
        if (self.used + aligned > self.cap) { return (void*)0; }
        let mut p: *void= (void*)((u8*)self.base + self.used);
        self.used = self.used + aligned;
        return p;
    }

    fn alloc_zeroed(self: *arena, n: u64) *void {
        let mut p: *void= self.alloc_bytes(n);
        if (p == (void*)0) { return (void*)0; }
        let mut b: *u8= (u8*)p;
        for (let mut i: u64 = 0; i < n; i = i + 1) { b[i] = 0; }
        return p;
    }

    fn save(self: *arena) void    { self.checkpoint = self.used; }
    fn restore(self: *arena) void { self.used = self.checkpoint; }
    fn reset(self: *arena) void   { self.used = 0; self.checkpoint = 0; }

    fn remaining(self: *arena) u64 { return self.cap - self.used; }

    fn deinit(self: *arena) void { free(self.base); }
}

} // alloc
} // std
