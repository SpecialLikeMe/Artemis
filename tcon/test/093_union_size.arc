union Big {
    i64 a;
    i32 b;
    i8  c;
}

i32 main() {
    if (sizeof(Big) < 8)         { return 1; }
    if (sizeof(Big) < sizeof(i64)) { return 2; }
    return 0;
}
