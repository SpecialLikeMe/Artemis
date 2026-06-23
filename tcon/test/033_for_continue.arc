i32 main() {
    i32 count = 0;
    for (i32 i = 0; i < 20; i++) {
        if (i % 3 != 0) { continue; }
        count = count + 1;
    }
    if (count != 7) { return 1; }
    return 0;
}
