i32 main() {
    comptime i32 N = 6;
    comptime i32 M = N + 1;
    i32 arr[7];
    arr[0] = M;
    if (M != 7) { return 1; }
    if (arr[0] != 7) { return 2; }
    return 0;
}
