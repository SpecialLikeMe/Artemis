// SMT claim: pointer proven non-null by SMT (address-of is always non-null) → verdict=GOOD.
// Taking &local gives abs_ptr{non_null} → no null-deref check emitted on dereference.
extern i32 printf(i8* fmt, ...);

i32 main() {
    i32 val = 42;
    i32* ptr = &val;

    // SMT knows ptr = &val → non_null; deref is GOOD, no check injected.
    i32 loaded = *ptr;
    if (loaded != 42) { printf("FAIL deref=%d\n", loaded); return 1; }

    // Pointer arithmetic within known bounds
    i32 arr[3];
    arr[0] = 100; arr[1] = 200; arr[2] = 300;
    i32* p = &arr[0];
    i32 v0 = *p;
    if (v0 != 100) { printf("FAIL arr ptr deref=%d\n", v0); return 2; }

    // Chain: pointer to pointer element
    i32* q = &arr[2];
    i32 v2 = *q;
    if (v2 != 300) { printf("FAIL arr[2] deref=%d\n", v2); return 3; }

    return 0;
}
