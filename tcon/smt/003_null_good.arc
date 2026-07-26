// SMT claim: pointer proven non-null by SMT (address-of is always non-null) → verdict=GOOD.
// Taking &local gives abs_ptr{non_null} → no null-deref check emitted on dereference.
@unsafe extern fn printf(fmt: *i8, ...) i32;

pub @unsafe fn main() i32 {
    let mut val: i32= 42;
    let mut ptr: *i32= &val;

    // SMT knows ptr = &val → non_null; deref is GOOD, no check injected.
    let mut loaded: i32= *ptr;
    if (loaded != 42) { printf("FAIL deref=%d\n", loaded); return 1; }

    // Pointer arithmetic within known bounds
    let mut arr: [3]i32;
    arr[0] = 100; arr[1] = 200; arr[2] = 300;
    let mut p: *i32= &arr[0];
    let mut v0: i32= *p;
    if (v0 != 100) { printf("FAIL arr ptr deref=%d\n", v0); return 2; }

    // Chain: pointer to pointer element
    let mut q: *i32= &arr[2];
    let mut v2: i32= *q;
    if (v2 != 300) { printf("FAIL arr[2] deref=%d\n", v2); return 3; }

    return 0;
}
