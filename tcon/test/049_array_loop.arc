i32 main() {
    i32 arr[10];
    for (i32 i = 0; i < 10; i++) {
        arr[i] = i * i;
    }
    i32 sum = 0;
    for (i32 i = 0; i < 10; i++) {
        sum = sum + arr[i];
    }
    if (sum != 285) { return 1; }
    return 0;
}
