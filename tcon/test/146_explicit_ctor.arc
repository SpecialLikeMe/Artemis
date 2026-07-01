istruc Num {
    i32 v;
    explicit void __construct__(Num* self, i32 a) { self.v = a; }
    i32 get(const Num* self) { return self.v; }
}
i32 main() {
    Num n(42);
    if (n.get() != 42) { return 1; }
    return 0;
}
