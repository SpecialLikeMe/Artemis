// Arena (bump) allocator: carves out slices from a single malloc'd block
extern void* malloc(u64 size);
extern void free(void* ptr);
extern void* memset(void* ptr, i32 val, u64 n);

istruc Arena {
    void* base;
    u64   used;
    u64   cap;

    void __construct__(Arena* self, u64 capacity) {
        self.base = malloc(capacity);
        self.used = 0;
        self.cap  = capacity;
    }

    void* alloc(Arena* self, u64 size) {
        if (self.used + size > self.cap) { return 0; }
        // Manually compute the pointer offset: base + used
        u8* p = (u8*)self.base;
        void* result = (void*)(p + self.used);
        self.used = self.used + size;
        return result;
    }

    void reset(Arena* self) { self.used = 0; }

    void deinit(Arena* self) { free(self.base); }
}

i32 main() {
    Arena arena(1024);
    if (arena.base == 0) { return 1; }

    i32* a = (i32*)arena.alloc(sizeof(i32));
    i32* b = (i32*)arena.alloc(sizeof(i32));
    i32* c = (i32*)arena.alloc(sizeof(i32));
    if (a == 0 || b == 0 || c == 0) { return 2; }

    (*a) = 1; (*b) = 2; (*c) = 3;
    if ((*a) + (*b) + (*c) != 6) { return 3; }

    if (arena.used != (u64)(sizeof(i32) * 3)) { return 4; }

    arena.reset();
    if (arena.used != 0) { return 5; }

    // Allocate again after reset — should reuse same memory
    i32* x = (i32*)arena.alloc(sizeof(i32) * 4);
    if (x == 0) { return 6; }
    x[0] = 10; x[1] = 20; x[2] = 30; x[3] = 40;
    if (x[0] + x[1] + x[2] + x[3] != 100) { return 7; }

    arena.deinit();
    return 0;
}
