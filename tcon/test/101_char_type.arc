i32 main() {
    char c = 'A';
    if (c != 65) { return 1; }
    char d = c;
    if (d != 'A') { return 2; }
    char lo = 'a';
    if (lo != 97) { return 3; }
    return 0;
}
