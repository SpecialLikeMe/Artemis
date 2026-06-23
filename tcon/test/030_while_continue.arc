i32 main() {
    i32 i = 0;
    i32 sum = 0;
    while (i < 10) {
        i = i + 1;
        if (i % 2 == 0) { continue; }
        sum = sum + i;
    }
    if (sum != 25) { return 1; }
    return 0;
}
