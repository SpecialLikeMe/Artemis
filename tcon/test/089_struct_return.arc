struct MinMax {
    i32 min;
    i32 max;
}

MinMax find_minmax(i32 a, i32 b) {
    MinMax r;
    if (a < b) { r.min = a; r.max = b; }
    else       { r.min = b; r.max = a; }
    return r;
}

i32 main() {
    MinMax mm = find_minmax(7, 3);
    if (mm.min != 3) { return 1; }
    if (mm.max != 7) { return 2; }

    MinMax mm2 = find_minmax(5, 5);
    if (mm2.min != 5) { return 3; }
    if (mm2.max != 5) { return 4; }
    return 0;
}
