i32 main() {
    f32 a = 1.5;
    f32 b = 2.5;
    f32 c = a + b;
    if (c != 4.0) { return 1; }
    f32 d = b - a;
    if (d != 1.0) { return 2; }
    f32 e = a * b;
    if (e != 3.75) { return 3; }
    return 0;
}
