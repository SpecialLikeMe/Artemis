i32 strlen_c(char* s) {
    i32 n = 0;
    while (s[n] != 0) { n = n + 1; }
    return n;
}

i32 main() {
    char* hello = "hello";
    if (strlen_c(hello) != 5) { return 1; }
    if (hello[0] != 'h') { return 2; }
    if (hello[4] != 'o') { return 3; }
    char* empty = "";
    if (strlen_c(empty) != 0) { return 4; }
    return 0;
}
