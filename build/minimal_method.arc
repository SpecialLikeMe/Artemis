istruc Foo {
    i32 x;
    void init(Foo* self, i32 v) { self.x = v; }
}
i32 main() {
    Foo f;
    f.init(42);
    return f.x;
}
