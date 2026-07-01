// Custom allocator: istruc wrapping malloc/free
extern void* malloc(u64 size);
extern void free(void* ptr);

istruc HeapAlloc {
    i32 count;

    void __construct__(&self) { self.count = 0; }

    void* alloc(&self, u64 size) {
        self.count = self.count + 1;
        return malloc(size);
    }

    void dealloc(&self, void* ptr) {
        self.count = self.count - 1;
        free(ptr);
    }

    i32 outstanding(&const self) { return self.count; }
}

i32 main() {
    HeapAlloc a;

    i32* p = (i32*)a.alloc(sizeof(i32) * 3);
    if (p == 0) { return 1; }
    if (a.outstanding() != 1) { return 2; }

    p[0] = 10; p[1] = 20; p[2] = 30;
    i32 sum = p[0] + p[1] + p[2];
    if (sum != 60) { return 3; }

    a.dealloc(p);
    if (a.outstanding() != 0) { return 4; }

    return 0;
}
