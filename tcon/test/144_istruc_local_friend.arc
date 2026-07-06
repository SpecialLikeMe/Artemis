// Verify that a regular function can access istruc fields via pointer
istruc Secret {
    i32 value;

    void __construct__(Secret* self, i32 v) {
        self.value = v;
    }

    i32 get(const Secret* self) {
        return self.value;
    }
}

i32 peek(Secret* s) {
    return (*s).get();
}

i32 main() {
    Secret s(77);
    if (s.get()  != 77) { return 1; }
    if (peek(&s) != 77) { return 2; }
    return 0;
}
