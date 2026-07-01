// FAIL: casting to an undeclared type
i32 main() {
    i32 x = (SomeUnknown)5;  // ERROR: SomeUnknown undeclared
    return x;
}
