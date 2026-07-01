i32 g_count = 0;

istruc Tracker {
    i32 id;

    void __construct__(Tracker* self, i32 n) {
        self.id = n;
        g_count = g_count + 1;
    }

    void __destruct__(Tracker* self) {
        g_count = g_count - 1;
    }

    i32 get(const Tracker* self) {
        return self.id;
    }
}

i32 main() {
    if (g_count != 0) { return 1; }

    Tracker t(42);
    if (g_count != 1)  { return 2; }
    if (t.get() != 42) { return 3; }

    t.__destruct__();
    if (g_count != 0)  { return 4; }

    return 0;
}
