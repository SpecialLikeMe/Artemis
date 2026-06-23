i32 main() {
    i32 i = 0;
    while (1) {
        if (i == 5) { break; }
        i = i + 1;
    }
    if (i != 5) { return 1; }
    return 0;
}
