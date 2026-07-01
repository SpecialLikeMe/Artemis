void f() noexcept { return; }
i32 main() {
    bool b = noexcept(f());
    if (!b) { return 1; }
    return 0;
}
