// std.alloc.arena — arena allocator with checkpoint/restore
extern std.alloc.arena;

i32 main() {
    arena a(8192);
    if (a.base == (void*)0) { return 1; }
    if (a.remaining() != 8192) { return 2; }

    // Alloc and write
    i32* p = (i32*)a.alloc_bytes(sizeof(i32) * 3);
    if (p == (i32*)0) { return 3; }
    p[0] = 1; p[1] = 2; p[2] = 3;
    if (p[0] + p[1] + p[2] != 6) { return 4; }

    // Save checkpoint
    a.save();
    u64 cp = a.checkpoint;

    // Alloc more
    i32* q = (i32*)a.alloc_bytes(sizeof(i32) * 2);
    if (q == (i32*)0) { return 5; }

    // Restore
    a.restore();
    if (a.used != cp) { return 6; }

    // Full reset
    a.reset();
    if (a.used != 0) { return 7; }
    if (a.checkpoint != 0) { return 8; }

    // alloc_zeroed clears memory
    u8* zp = (u8*)a.alloc_zeroed((u64)16);
    if (zp == (u8*)0) { return 9; }
    i32 any_nonzero = 0;
    for (i32 i = 0; i < 16; i = i + 1) {
        if (zp[i] != 0) { any_nonzero = 1; break; }
    }
    if (any_nonzero) { return 10; }

    a.deinit();
    return 0;
}
