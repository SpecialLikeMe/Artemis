i32 g_a = 1;
i32 g_b = 2;
i32 g_c = 3;

i32 sum_globals() { return g_a + g_b + g_c; }

i32 main() {
    if (sum_globals() != 6) { return 1; }
    g_a = 10;
    g_b = 20;
    if (sum_globals() != 33) { return 2; }
    return 0;
}
