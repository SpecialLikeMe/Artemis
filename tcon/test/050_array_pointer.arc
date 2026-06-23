i32 sum_array(i32* arr, i32 n) {
    i32 s = 0;
    for (i32 i = 0; i < n; i++) {
        s = s + arr[i];
    }
    return s;
}

i32 main() {
    i32 a[5];
    a[0] = 1; a[1] = 2; a[2] = 3; a[3] = 4; a[4] = 5;
    i32 s = sum_array(a, 5);
    if (s != 15) { return 1; }
    return 0;
}
