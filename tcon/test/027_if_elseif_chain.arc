i32 classify(i32 n) {
    if (n < 0)       { return -1; }
    else if (n == 0) { return 0; }
    else if (n < 10) { return 1; }
    else             { return 2; }
}

i32 main() {
    if (classify(-5)  != -1) { return 1; }
    if (classify(0)   != 0)  { return 2; }
    if (classify(7)   != 1)  { return 3; }
    if (classify(100) != 2)  { return 4; }
    return 0;
}
