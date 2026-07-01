// sizeof applied to expressions and pointer types
i32 main() {
    i32 x = 0;
    if (sizeof(x)   != 4) { return 1; }
    if (sizeof(i32*) != 8) { return 2; }  // pointer is 8 bytes on 64-bit
    i64 y = 0;
    if (sizeof(y)   != 8) { return 3; }
    return 0;
}
