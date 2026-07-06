// PASS: range-based for loop works over a runtime-length std.vector via .length field.
extern std.vector;

extern void* malloc(u64 n);
extern void  free(void* p);

// Minimal inline allocator so the test has no external deps beyond malloc/free.
memstr HeapBump {
    void* base;
    u64   used;
    u64   cap;
    void __construct__(HeapBump* self, u64 capacity) {
        self.base = malloc(capacity);
        self.used = 0;
        self.cap  = capacity;
    }
    void* mmap(HeapBump* self, u64 n) {
        u64 aligned = (n + 7) & ~(u64)7;
        if (self.used + aligned > self.cap) { return (void*)0; }
        void* p = (void*)((u8*)self.base + self.used);
        self.used = self.used + aligned;
        return p;
    }
    void rmap(HeapBump* self, void* p, u64 n) {}
    void deinit(HeapBump* self) { free(self.base); }
}

i32 main() {
    HeapBump bump(8192);

    std.vector<i32> v(4, bump);
    v.push(10, bump);
    v.push(20, bump);
    v.push(30, bump);

    i32 sum = 0;
    for (i32 x : v) {
        sum = sum + x;
    }
    if (sum != 60) { return 1; }

    bump.deinit();
    return 0;
}
