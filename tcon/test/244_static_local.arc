// PASS: static local variable persists across function calls.
i32 counter() {
    static i32 n = 0;
    n = n + 1;
    return n;
}
i32 main() {
    if (counter() != 1) { return 1; }
    if (counter() != 2) { return 2; }
    if (counter() != 3) { return 3; }
    return 0;
}
