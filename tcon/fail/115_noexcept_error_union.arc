// FAIL: a noexcept function cannot be declared as !T (error union return)
auto compute() noexcept !i32 {
    return 42;
}

i32 main() { return 0; }
