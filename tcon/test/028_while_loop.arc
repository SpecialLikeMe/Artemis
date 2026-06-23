i32 main() {
    i32 i = 0;
    i32 sum = 0;
    while (i < 10) {
        sum = sum + i;
        i = i + 1;
    }
    if (sum != 45) { return 1; }
    if (i != 10)   { return 2; }
    return 0;
}
