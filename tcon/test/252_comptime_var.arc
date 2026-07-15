// PASS: comptime variable is evaluated and usable at compile time.
i32 main() {
    comptime i32 N = 10;
    if (N != 10) { return 1; }

    comptime i32 M = N * 2;
    if (M != 20) { return 2; }

    i32 arr[10];
    i32 i = 0;
    while (i < N) { arr[i] = i; i = i + 1; }
    if (arr[9] != 9) { return 3; }

    return 0;
}
