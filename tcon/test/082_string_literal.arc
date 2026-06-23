i32 strlen_impl(const i8* s) {
    i32 n = 0;
    while (s[n] != 0) { n = n + 1; }
    return n;
}

i32 main() {
    const i8* hello = "hello";
    if (strlen_impl(hello) != 5) { return 1; }
    const i8* empty = "";
    if (strlen_impl(empty) != 0) { return 2; }
    return 0;
}
