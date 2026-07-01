// local keyword: like C++ friend — allows a non-member function to access class fields
// For test purposes: verify local-declared function can be called

istruc Secret {
    private i32 value;

    void __construct__(&self, i32 v) {
        self.value = v;
    }

    i32 get(&const self) {
        return self.value;
    }

    local i32 peek(Secret* s);
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
