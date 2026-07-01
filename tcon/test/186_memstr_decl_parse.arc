// memstr declaration: the compiler accepts the memstr keyword with class-body syntax.
// A memstr type is a first-class allocator type that is valid for &memstr parameters.
extern void* malloc(u64 n);
extern void free(void* p);

// memstr with class-body syntax (methods + fields)
memstr BumpAlloc {
    void* base;
    u64   used;
    u64   cap;

    void __construct__(BumpAlloc* self, u64 capacity) {
        self.base = malloc(capacity);
        self.used = 0;
        self.cap  = capacity;
    }

    void* alloc_bytes(BumpAlloc* self, u64 n) {
        u64 aligned = (n + 7) & ~(u64)7;
        if (self.used + aligned > self.cap) { return (void*)0; }
        void* p = (void*)((u8*)self.base + self.used);
        self.used = self.used + aligned;
        return p;
    }

    void deinit(BumpAlloc* self) { free(self.base); }
}

i32 main() {
    BumpAlloc a(1024);
    if (a.base == (void*)0) { return 1; }

    i32* p = (i32*)a.alloc_bytes(sizeof(i32) * 4);
    if (p == (i32*)0) { return 2; }

    p[0] = 10; p[1] = 20; p[2] = 30; p[3] = 40;
    i32 sum = p[0] + p[1] + p[2] + p[3];
    if (sum != 100) { return 3; }

    a.deinit();
    return 0;
}
