i32 main() {
    i32 a = 10;
    i32 b = 20;
    i32 mx = a > b ? a : b;
    if (mx != 20) { return 1; }
    i32 mn = a < b ? a : b;
    if (mn != 10) { return 2; }
    i32 c = 0 ? 99 : 42;
    if (c != 42)  { return 3; }
    return 0;
}
