// std.alloc.slab — slab allocator for fixed-size objects
extern std.alloc.slab;

i32 main() {
    // Slab of 8-byte objects (i64 size)
    slab s((u64)8);
    if (s.head != (void*)0) { return 1; }

    // Alloc some objects (will trigger slab_page creation)
    i64* p1 = (i64*)s.alloc_obj();
    if (p1 == (i64*)0) { return 2; }
    (*p1) = 12345678;

    i64* p2 = (i64*)s.alloc_obj();
    if (p2 == (i64*)0) { return 3; }
    (*p2) = 87654321;

    if ((*p1) != 12345678) { return 4; }
    if ((*p2) != 87654321) { return 5; }

    // Free and reuse
    s.free_obj((void*)p1);
    i64* p3 = (i64*)s.alloc_obj();
    if (p3 == (i64*)0) { return 6; }
    (*p3) = 99999;
    if ((*p3) != 99999) { return 7; }

    s.free_obj((void*)p2);
    s.free_obj((void*)p3);

    return 0;
}
