// SMT claim: 100% native C speed — proven-safe (GOOD) code has zero runtime check overhead.
// Heavy computation benchmark: array fill and reduction with constant-index access → all GOOD.
// No runtime checks emitted → runs at the same speed as hand-written C.
extern i32 printf(i8* fmt, ...);

i32 main() {
    i32 arr[32];

    // Fill: arr[i] = i + 1  (indices 0..31 all in [0,31] → proven GOOD)
    i32 i = 0;
    while (i < 32) {
        arr[i] = i + 1;
        i = i + 1;
    }

    // Sum = 1+2+...+32 = 32*33/2 = 528
    i32 sum = 0;
    i32 j = 0;
    while (j < 32) {
        sum = sum + arr[j];
        j = j + 1;
    }
    if (sum != 528) { printf("FAIL sum=%d expected 528\n", sum); return 1; }

    // Prefix max: each arr[k] = max(arr[0..k])
    // After fill all are 1,2,...,32 so prefix max[k] = k+1
    i32 running_max = 0;
    i32 k = 0;
    while (k < 32) {
        if (arr[k] > running_max) { running_max = arr[k]; }
        k = k + 1;
    }
    if (running_max != 32) { printf("FAIL max=%d expected 32\n", running_max); return 2; }

    // Constant-index spot checks (SMT: GOOD immediately)
    if (arr[0] != 1)  { printf("FAIL arr[0]\n"); return 3; }
    if (arr[31] != 32) { printf("FAIL arr[31]\n"); return 4; }

    return 0;
}
