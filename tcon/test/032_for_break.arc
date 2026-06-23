i32 main() {
    i32 found = -1;
    for (i32 i = 0; i < 100; i++) {
        if (i * i == 49) {
            found = i;
            break;
        }
    }
    if (found != 7) { return 1; }
    return 0;
}
