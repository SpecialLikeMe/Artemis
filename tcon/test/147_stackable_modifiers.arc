istruc Base {
    i32 v;
    virtual i32 f(&const self) { return self.v; }
}
istruc Sub : Base {
    public final i32 f(&const self) noexcept const override { return self.v + 1; }
}
i32 main() {
    Sub s;
    s.v = 10;
    if (s.f() != 11) { return 1; }
    return 0;
}
