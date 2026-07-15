// PASS: volatile qualifier marks variables for volatile load/store.
i32 main() {
    volatile i32 x = 42;
    volatile i32 y = 0;
    y = x + 1;
    if (y != 43) { return 1; }
    return 0;
}
