// std.alloc.arena — Region/arena allocator with sub-regions.
// Allocates a large block upfront; sub-arenas can checkpoint and rollback.
extern void* malloc(u64 n);
extern void  free(void* p);

namespace std {
namespace alloc {

memstr arena {
    void* base;
    u64   used;
    u64   cap;
    u64   checkpoint;

    void __construct__(&self, u64 capacity) {
        self.base       = malloc(capacity);
        self.used       = 0;
        self.cap        = capacity;
        self.checkpoint = 0;
    }

    void* alloc_bytes(&self, u64 n) {
        u64 aligned = (n + 7) & ~(u64)7;
        if (self.used + aligned > self.cap) { return (void*)0; }
        void* p = (void*)((u8*)self.base + self.used);
        self.used = self.used + aligned;
        return p;
    }

    void* alloc_zeroed(&self, u64 n) {
        void* p = self.alloc_bytes(n);
        if (p == (void*)0) { return (void*)0; }
        u8* b = (u8*)p;
        for (u64 i = 0; i < n; i = i + 1) { b[i] = 0; }
        return p;
    }

    void save(&self)    { self.checkpoint = self.used; }
    void restore(&self) { self.used = self.checkpoint; }
    void reset(&self)   { self.used = 0; self.checkpoint = 0; }

    u64 remaining(&self) { return self.cap - self.used; }

    void deinit(&self) { free(self.base); }
}

} // alloc
} // std
