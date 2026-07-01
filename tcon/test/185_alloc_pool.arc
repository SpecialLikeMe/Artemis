// Fixed-size pool allocator: pre-allocates N slots, O(1) alloc/free
// Free-slot stack stores void* pointers directly (no pointer arithmetic needed).
extern "C" { void* malloc(u64 size); void free(void* ptr); }

istruc Pool {
    void* free_slots[16];   // stack of available slot pointers
    i32   top;              // number of free slots remaining
    void* block;            // backing allocation

    void __construct__(&self, u64 elem_size, i32 n) {
        self.block = malloc(elem_size * (u64)n);
        self.top   = 0;
        u8* p = (u8*)self.block;
        for (i32 i = 0; i < n; i = i + 1) {
            self.free_slots[self.top] = (void*)(p + elem_size * (u64)i);
            self.top = self.top + 1;
        }
    }

    void* acquire(&self) {
        if (self.top == 0) { return (void*)0; }
        self.top = self.top - 1;
        return self.free_slots[self.top];
    }

    void release(&self, void* p) {
        if (self.top < 16) {
            self.free_slots[self.top] = p;
            self.top = self.top + 1;
        }
    }

    void deinit(&self) { free(self.block); }
}

i32 main() {
    Pool pool(sizeof(i32), 8);
    if (pool.block == 0) { return 1; }
    if (pool.top != 8)   { return 2; }

    i32* a = (i32*)pool.acquire();
    i32* b = (i32*)pool.acquire();
    i32* c = (i32*)pool.acquire();
    if (a == 0 || b == 0 || c == 0) { return 3; }
    if (pool.top != 5) { return 4; }

    (*a) = 10; (*b) = 20; (*c) = 30;
    if ((*a) + (*b) + (*c) != 60) { return 5; }

    pool.release(b);
    if (pool.top != 6) { return 6; }

    // Reacquire from pool — gets the slot we just released
    i32* d = (i32*)pool.acquire();
    if (d == 0)        { return 7; }
    if (pool.top != 5) { return 8; }

    pool.release(a);
    pool.release(c);
    pool.release(d);
    if (pool.top != 8) { return 9; }

    pool.deinit();
    return 0;
}
