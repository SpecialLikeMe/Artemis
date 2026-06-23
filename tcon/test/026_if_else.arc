i32 main() {
    i32 x = 5;
    i32 r = 0;
    if (x > 3) {
        r = 1;
    } else {
        r = 2;
    }
    if (r != 1) { return 1; }

    if (x < 3) {
        r = 10;
    } else {
        r = 20;
    }
    if (r != 20) { return 2; }
    return 0;
}
