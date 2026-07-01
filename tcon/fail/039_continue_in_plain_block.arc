// FAIL: continue used in a plain block (not a loop)
i32 main() {
    i32 x = 0;
    {
        x = 1;
        continue;  // ERROR: not in a loop
    }
    return x;
}
