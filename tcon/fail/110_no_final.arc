// final override: marks that no further class may override the method
istruc A {
    virtual i32 val(const A* self) { return 1; }
}
istruc B : A {
    final i32 val(const B* self) override { return 2; }
    i32 doubled(const B* self) { return self.val() * 2; }
}

i32 main() {
    B b;
    if (b.val()     != 2) { return 1; }
    if (b.doubled() != 4) { return 2; }
    return 0;
}
