i32 main() {
    i32 x = 1;
    i32 r = 0;
    switch (x) {
        case 1: r = r + 1;
        case 2: r = r + 2;
        default: r = r + 4;
    }
    if (r != 7) { return 1; }
    return 0;
}
