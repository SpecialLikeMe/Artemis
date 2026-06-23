i32 g_val = 0;

void set_val(i32 v) {
    g_val = v;
}

void add_to_val(i32 v) {
    g_val = g_val + v;
}

i32 main() {
    set_val(10);
    if (g_val != 10) { return 1; }
    add_to_val(5);
    if (g_val != 15) { return 2; }
    return 0;
}
