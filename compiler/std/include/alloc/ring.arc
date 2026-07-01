// std.alloc.ring — Ring/circular buffer allocator.
// Allocates in a circular fashion; oldest allocation is overwritten when buffer wraps.
// Suitable for temporary scratch buffers in tight loops.
extern void* malloc(u64 n);
extern void  free(void* p);

namespace std {
namespace alloc {

memstr ring {
    void* base;
    u64   cap;
    u64   head;

    void __construct__(ring* self, u64 capacity) {
        self.base = malloc(capacity);
        self.cap  = capacity;
        self.head = 0;
    }

    void* alloc_bytes(ring* self, u64 n) {
        u64 aligned = (n + 7) & ~(u64)7;
        if (aligned > self.cap) { return (void*)0; }
        if (self.head + aligned > self.cap) { self.head = 0; }
        void* p = (void*)((u8*)self.base + self.head);
        self.head = self.head + aligned;
        return p;
    }

    void reset(ring* self) { self.head = 0; }

    void deinit(ring* self) { free(self.base); }
}

} // alloc
} // std
