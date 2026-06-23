i32 main() {
    i32 big = 0x141;
    i8  small = (i8)big;
    if (small != 0x41) { return 1; }
    return 0;
}
