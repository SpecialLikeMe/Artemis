// FAIL: using an undeclared type must be rejected
i32 main() {
    Blarg x;  // ERROR: 'Blarg' is not a known type
    return 0;
}
