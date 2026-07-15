i32 g_count = 0;
istruc Tracker {
    i32 id;
    void __construct__(Tracker* self, i32 n) {
        self.id = n;
        g_count = g_count + 1;
    }
}
i32 main() {
    return 0;
}
