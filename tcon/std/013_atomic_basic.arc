// Test: std.atomic — atomic types default construction and field access
extern  std.atomic;
@unsafe extern fn printf(fmt: *i8, ...) i32;

pub @unsafe fn main() i32 {
    // i32_t default construct (val = 0)
    let mut a: std.atomic.i32_t;
    if (a.val != 0) { printf("FAIL i32_t default val\n"); return 1; }

    // Manually set and check val
    a.val = 42;
    if (a.val != 42) { printf("FAIL i32_t set val\n"); return 2; }

    // i64_t default construct
    let mut c: std.atomic.i64_t;
    if (c.val != 0) { printf("FAIL i64_t default val\n"); return 3; }

    // bool_t default construct
    let mut f: std.atomic.bool_t;
    if (f.val != 0) { printf("FAIL bool_t default val\n"); return 4; }

    f.val = 1;
    if (f.val == 0) { printf("FAIL bool_t set val\n"); return 5; }

    // spin_lock constructs with locked = 0
    let mut lk: std.atomic.spin_lock;
    if (lk.locked.val != 0) { printf("FAIL spin_lock init\n"); return 6; }

    // ref_count constructs with count.val = 1
    let mut rc: std.atomic.ref_count();
    if (rc.count.val != 1) { printf("FAIL ref_count init\n"); return 7; }

    return 0;
}
