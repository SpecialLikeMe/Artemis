// FAIL: calling a generic function that does not exist
i32 main() {
    i32 x = no_such_generic<i32>(5);  // ERROR: undeclared
    return x;
}
