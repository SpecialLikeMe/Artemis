i32 table[5];

void init_table() {
    for (i32 i = 0; i < 5; i++) {
        table[i] = i * 10;
    }
}

i32 main() {
    init_table();
    if (table[0] != 0)  { return 1; }
    if (table[1] != 10) { return 2; }
    if (table[4] != 40) { return 3; }
    return 0;
}
