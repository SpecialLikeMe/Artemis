void greet() noexcept { return; }
i32 add(i32 a, i32 b) noexcept { return a + b; }
istruc W {
    i32 v;
    i32 get(&const self) noexcept const { return self.v; }
}
i32 main() {
    greet();
    if (add(2, 3) != 5) { return 1; }
    W w;
    w.v = 9;
    if (w.get() != 9) { return 2; }
    return 0;
}
