inline i32 clamp(i32 v, i32 lo, i32 hi) {
    if (v < lo) { return lo; }
    if (v > hi) { return hi; }
    return v;
}

i32 main() {
    if (clamp(5, 0, 10)   != 5)  { return 1; }
    if (clamp(-5, 0, 10)  != 0)  { return 2; }
    if (clamp(15, 0, 10)  != 10) { return 3; }
    return 0;
}
