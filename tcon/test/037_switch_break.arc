i32 main() {
    i32 r = 0;
    for (i32 i = 0; i < 3; i++) {
        switch (i) {
            case 0: r = r + 1; break;
            case 1: r = r + 10; break;
            default: r = r + 100; break;
        }
    }
    if (r != 111) { return 1; }
    return 0;
}
