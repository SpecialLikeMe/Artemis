i32 main() {
    i32 a = -10;
    i32 b = -20;
    if (a + b != -30)  { return 1; }
    if (a - b != 10)   { return 2; }
    if (a * b != 200)  { return 3; }
    if (a / b != 0)    { return 4; }
    if (-a != 10)      { return 5; }
    if (a < b)         { return 6; }
    return 0;
}
