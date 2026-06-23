i32 main() {
    i32 outer = 0;
    i32 inner_total = 0;
    while (outer < 3) {
        i32 inner = 0;
        while (1) {
            if (inner >= 3) { break; }
            inner_total = inner_total + 1;
            inner = inner + 1;
        }
        outer = outer + 1;
    }
    if (outer != 3)       { return 1; }
    if (inner_total != 9) { return 2; }
    return 0;
}
