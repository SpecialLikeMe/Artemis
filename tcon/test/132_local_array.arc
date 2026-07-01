i32 sum(i32 n) {
    i32 a[5];
    a[0] = 1;
    a[1] = 2;
    a[2] = 3;
    a[3] = 4;
    a[4] = 5;
    i32 s = 0;
    i32 i = 0;
    while (i < n) {
        s = s + a[i];
        i = i + 1;
    }
    return s;
}

i32 main() {
    if (sum(5) != 15) { return 1; }
    if (sum(3) != 6)  { return 2; }
    if (sum(0) != 0)  { return 3; }
    return 0;
}
