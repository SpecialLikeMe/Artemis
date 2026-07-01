// FAIL: using a variable declared in an inner scope from an outer scope
i32 main() {
    { i32 inner = 5; }
    return inner;  // ERROR: inner is out of scope
}
