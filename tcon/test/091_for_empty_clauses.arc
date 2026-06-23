i32 main() {
    i32 i = 0;
    i32 sum = 0;
    for (; i < 5; ) {
        sum = sum + i;
        i++;
    }
    if (sum != 10) { return 1; }
    if (i != 5)    { return 2; }
    return 0;
}
