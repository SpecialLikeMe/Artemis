// FAIL: 'override' used on a class with no base class must be rejected
istruc Lone {
    i32 f(&const self) override { return 1; }  // ERROR: override without base class
}

i32 main() { return 0; }
