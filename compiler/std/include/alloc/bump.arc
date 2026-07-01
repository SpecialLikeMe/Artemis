// std.alloc.bump — Bump (linear) allocator.
// Allocates by advancing a pointer; free is a no-op; reset reclaims all memory at once.
extern void* malloc(u64 n);
extern void  free(void* p);

namespace std {
namespace alloc {

memstr bump {
    void* base;
    u64   used;
    u64   cap;

    void __construct__(bump* self, u64 capacity) {
        self.base = malloc(capacity);
        self.used = 0;
        self.cap  = capacity;
    }

    void* alloc_raw(bump* self, u64 size, u64 align) {
        u64 offset = self.used;
        // Align up: round offset up to the nearest multiple of align
        u64 rem = offset % align;
        if (rem != 0) { offset = offset + (align - rem); }
        if (offset + size > self.cap) { return (void*)0; }
        void* ptr = (void*)((u8*)self.base + offset);
        self.used = offset + size;
        return ptr;
    }

    void* alloc_bytes(bump* self, u64 n) { return self.alloc_raw(n, (u64)8); }

    void reset(bump* self) { self.used = 0; }

    void deinit(bump* self) { free(self.base); }
}

} // alloc
} // std
