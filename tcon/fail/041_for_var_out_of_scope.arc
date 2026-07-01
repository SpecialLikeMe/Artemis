// FAIL: using a for-loop variable after the loop ends
i32 main() {
    for (i32 i = 0; i < 5; i = i + 1) {}
    return i;  // ERROR: i is out of scope
}
