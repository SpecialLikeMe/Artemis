// FAIL: 'override' in a class with no base class
istruc Lone {
    i32 f(const Lone* self) override { return 1; }  // ERROR: no base to override
}
i32 main() { return 0; }
