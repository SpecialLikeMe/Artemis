i32 main() {
    i32 arr[5];
    for (i32 i = 0; i < 5; i++) { arr[i] = i * 2; }

    i32* p = arr;
    if (*p != 0)       { return 1; }
    p = p + 1;
    if (*p != 2)       { return 2; }
    p = p + 2;
    if (*p != 6)       { return 3; }
    p = p - 1;
    if (*p != 4)       { return 4; }
    return 0;
}
