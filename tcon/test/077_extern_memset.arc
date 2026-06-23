extern void* memset(void* ptr, i32 val, u64 n);

i32 main() {
    i32 arr[8];
    memset(arr, 0, sizeof(i32) * 8);
    for (i32 i = 0; i < 8; i++) {
        if (arr[i] != 0) { return 1; }
    }
    return 0;
}
