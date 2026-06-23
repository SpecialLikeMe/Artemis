i32 main() {
    i32 count = 0;
    for (i32 i = 0; i < 5; i++) {
        for (i32 j = 0; j < 5; j++) {
            count = count + 1;
        }
    }
    if (count != 25) { return 1; }
    return 0;
}
