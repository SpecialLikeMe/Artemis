i32 main() {
    char a = 'A';
    char z = 'Z';
    if (a >= z) { return 1; }
    if (a != 65) { return 2; }
    if (z != 90) { return 3; }
    char mid = 'M';
    if (mid < a) { return 4; }
    if (mid > z) { return 5; }
    return 0;
}
