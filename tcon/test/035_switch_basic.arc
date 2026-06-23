i32 day_num(i32 d) {
    switch (d) {
        case 1: return 10;
        case 2: return 20;
        case 3: return 30;
        default: return 0;
    }
}

i32 main() {
    if (day_num(1) != 10) { return 1; }
    if (day_num(2) != 20) { return 2; }
    if (day_num(3) != 30) { return 3; }
    if (day_num(9) != 0)  { return 4; }
    return 0;
}
