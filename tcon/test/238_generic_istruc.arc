// PASS: generic istruc (istruc Foo<T>) with multiple instantiations.
istruc Box<T> {
    T val;
    void set(Box<T>* self, T v) { self.val = v; }
    T    get(Box<T>* self)      { return self.val; }
}
i32 main() {
    Box<i32> bi;
    bi.set(42);
    if (bi.get() != 42) { return 1; }

    Box<i64> bl;
    bl.set((i64)1000000);
    if (bl.get() != (i64)1000000) { return 2; }

    return 0;
}
