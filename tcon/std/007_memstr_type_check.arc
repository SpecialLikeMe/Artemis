// Tests that a memstr type constructs, allocates, and frees correctly.
extern void* malloc(u64 n);
extern void  free(void* p);

memstr MyAlloc {
    void* base;
    u64   used;
    u64   cap;

    void __construct__(&self, u64 capacity) {
        self.base = malloc(capacity);
        self.used = (u64)0;
        self.cap  = capacity;
    }

    void* alloc_bytes(&self, u64 n) {
        if (self.used + n > self.cap) { return (void*)0; }
        void* p = (void*)((u8*)self.base + self.used);
        self.used = self.used + n;
        return p;
    }

    void deinit(&self) { free(self.base); }
}

i32 main() {
    MyAlloc a(1024);
    if (a.base == (void*)0) { return 1; }

    // Alloc five i32s, write values
    i32* p0 = (i32*)a.alloc_bytes((u64)4);
    i32* p1 = (i32*)a.alloc_bytes((u64)4);
    i32* p2 = (i32*)a.alloc_bytes((u64)4);
    i32* p3 = (i32*)a.alloc_bytes((u64)4);
    i32* p4 = (i32*)a.alloc_bytes((u64)4);
    if (p0 == (i32*)0) { return 2; }
    if (p4 == (i32*)0) { return 3; }

    (*p0) = 0;
    (*p1) = 2;
    (*p2) = 4;
    (*p3) = 6;
    (*p4) = 8;

    if ((*p0) != 0)  { return 10; }
    if ((*p1) != 2)  { return 11; }
    if ((*p2) != 4)  { return 12; }
    if ((*p3) != 6)  { return 13; }
    if ((*p4) != 8)  { return 14; }

    a.deinit();
    return 0;
}
