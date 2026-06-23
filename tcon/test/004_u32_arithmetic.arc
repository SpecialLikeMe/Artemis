i32 main() {
    u32 a = 100;
    u32 b = 37;
    if (a + b != 137) { return 1; }
    if (a - b != 63)  { return 2; }
    if (a * b != 3700) { return 3; }
    if (a / b != 2)   { return 4; }
    if (a % b != 26)  { return 5; }
    return 0;
}
