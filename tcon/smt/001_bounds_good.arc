// SMT claim: static array access with constant index is proven GOOD — zero runtime overhead.
// The SMT interval domain knows idx=2 is in [0,4], verdict=GOOD, no check emitted.
extern i32 printf(i8* fmt, ...);

i32 main() {
    i32 arr[5];
    arr[0] = 10;
    arr[1] = 20;
    arr[2] = 30;
    arr[3] = 40;
    arr[4] = 50;

    // All accesses use constant indices — SMT proves GOOD for each.
    i32 sum = arr[0] + arr[1] + arr[2] + arr[3] + arr[4];
    if (sum != 150) { printf("FAIL sum=%d expected 150\n", sum); return 1; }

    // Constant index at boundary
    i32 first = arr[0];
    i32 last  = arr[4];
    if (first != 10 || last != 50) { printf("FAIL boundary\n"); return 2; }

    return 0;
}
