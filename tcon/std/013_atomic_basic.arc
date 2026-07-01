// Test: std.atomic — atomic types default construction and field access
extern std.atomic;
extern i32 printf(i8* fmt, ...);

i32 main() {
    // i32_t default construct (val = 0)
    i32_t a;
    if (a.val != 0) { printf("FAIL i32_t default val\n"); return 1; }

    // Manually set and check val
    a.val = 42;
    if (a.val != 42) { printf("FAIL i32_t set val\n"); return 2; }

    // i64_t default construct
    i64_t c;
    if (c.val != 0) { printf("FAIL i64_t default val\n"); return 3; }

    // bool_t default construct
    bool_t f;
    if (f.val != 0) { printf("FAIL bool_t default val\n"); return 4; }

    f.val = 1;
    if (f.val == 0) { printf("FAIL bool_t set val\n"); return 5; }

    // spin_lock constructs with locked = 0
    spin_lock lk;
    if (lk.locked.val != 0) { printf("FAIL spin_lock init\n"); return 6; }

    // ref_count constructs with count.val = 1
    ref_count rc;
    if (rc.count.val != 1) { printf("FAIL ref_count init\n"); return 7; }

    return 0;
}
