union Bytes {
    i32 word;
    i8  b0;
}

i32 main() {
    Bytes u;
    u.word = 0x41424344;
    i8 first = u.b0;
    if (first != 0x44 && first != 0x41) { return 1; }
    return 0;
}
