// std.alloc.pool — fixed-size object pool
extern std.alloc.pool;

i32 main() {
    // Pool of 8 slots, each 4 bytes (i32)
    pool p(8, (u64)4);
    if (p.base == (void*)0) { return 1; }
    if (p.empty() == false) { return 2; }  // initially all free = "empty" (no used slots)
    if (p.full() == true) { return 3; }

    // Allocate all 8 slots
    void* slots[8];
    for (i32 i = 0; i < 8; i = i + 1) {
        slots[i] = p.alloc_slot();
        if (slots[i] == (void*)0) { return 10 + i; }
        *((i32*)slots[i]) = i * 10;
    }
    if (p.full() == false) { return 20; }
    if (p.used_count() != 8) { return 21; }

    // One more should return null (pool full)
    void* extra = p.alloc_slot();
    if (extra != (void*)0) { return 22; }

    // Verify values
    for (i32 i = 0; i < 8; i = i + 1) {
        if (*((i32*)slots[i]) != i * 10) { return 30 + i; }
    }

    // Free all slots
    for (i32 i = 0; i < 8; i = i + 1) {
        p.free_slot(slots[i]);
    }
    if (p.empty() == false) { return 40; }

    p.deinit();
    return 0;
}
