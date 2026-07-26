// std.alloc.pool — fixed-size object pool
extern  std.alloc.pool;

pub fn main() i32 {
    // Pool of 8 slots, each 4 bytes (i32)
    let mut p: std.alloc.pool((u64)8, (u64)4);
    if (p.base == (void*)0) { return 1; }
    if (p.empty() == false) { return 2; }  // initially all free = "empty" (no used slots)
    if (p.full() == true) { return 3; }

    // Allocate all 8 slots
    let mut slots: [8]*void;
    for (let mut i: i32 = 0; i < 8; i = i + 1) {
        slots[i] = p.alloc_slot();
        if (slots[i] == (void*)0) { return 10 + i; }
        *((i32*)slots[i]) = i * 10;
    }
    if (p.full() == false) { return 20; }
    if (p.used_count() != 8) { return 21; }

    // One more should return null (pool full)
    let mut extra: *void= p.alloc_slot();
    if (extra != (void*)0) { return 22; }

    // Verify values
    for (let mut i: i32 = 0; i < 8; i = i + 1) {
        if (*((i32*)slots[i]) != i * 10) { return 30 + i; }
    }

    // Free all slots
    for (let mut i: i32 = 0; i < 8; i = i + 1) {
        p.free_slot(slots[i]);
    }
    if (p.empty() == false) { return 40; }

    p.deinit();
    return 0;
}
