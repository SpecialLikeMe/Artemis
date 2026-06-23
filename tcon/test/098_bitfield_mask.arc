i32 get_bits(i32 val, i32 lo, i32 hi) {
    i32 mask = ((1 << (hi - lo + 1)) - 1) << lo;
    return (val & mask) >> lo;
}

i32 main() {
    i32 v = 0xAB;
    if (get_bits(v, 0, 3) != 0xB) { return 1; }
    if (get_bits(v, 4, 7) != 0xA) { return 2; }
    i32 w = 0xFF00;
    if (get_bits(w, 8, 15) != 0xFF) { return 3; }
    return 0;
}
