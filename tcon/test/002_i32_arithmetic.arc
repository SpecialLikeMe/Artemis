i32 main() {
    i32 a = 10;
    i32 b = 3;
    if (a + b != 13) { return 1; }
    if (a - b != 7)  { return 2; }
    if (a * b != 30) { return 3; }
    if (a / b != 3)  { return 4; }
    if (a % b != 1)  { return 5; }
    return 0;
}
