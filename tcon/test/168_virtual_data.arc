// virtual data member declared in base, stored in derived
istruc Base {
    virtual i32 tag;
}
istruc Child : Base {
    i32 tag;
    void __construct__(&self, i32 t) { self.tag = t; }
    i32 get(&const self) { return self.tag; }
}

i32 main() {
    Child c(42);
    if (c.get() != 42) { return 1; }
    if (c.tag   != 42) { return 2; }
    return 0;
}
