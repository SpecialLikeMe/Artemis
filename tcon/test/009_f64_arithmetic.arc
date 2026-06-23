i32 main() {
    f64 a = 3.14;
    f64 b = 2.0;
    f64 c = a * b;
    if (c != 6.28) { return 1; }
    f64 d = a / b;
    if (d != 1.57) { return 2; }
    return 0;
}
