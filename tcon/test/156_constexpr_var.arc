i32 main() {
    constexpr i32 N = 6;
    constexpr i32 M = N + 1;
    i32 arr[7];
    arr[0] = M;
    if (M != 7) { return 1; }
    if (arr[0] != 7) { return 2; }
    return 0;
}
