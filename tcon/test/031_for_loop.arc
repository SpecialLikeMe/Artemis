i32 main() {
    i32 sum = 0;
    for (i32 i = 0; i < 10; i++) {
        sum = sum + i;
    }
    if (sum != 45) { return 1; }
    return 0;
}
