// FAIL: break used in a plain block (not a loop or switch)
i32 main() {
    i32 x = 0;
    {
        x = 1;
        break;  // ERROR: not in a loop or switch
    }
    return x;
}
