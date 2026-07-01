// FAIL: undeclared identifier used as array index
i32 main() {
    i32 arr[5];
    arr[0] = 1;
    return arr[phantom_idx];  // ERROR: phantom_idx undeclared
}
