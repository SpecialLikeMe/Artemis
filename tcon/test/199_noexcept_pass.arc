//  functions that contain no try/res/error-union return compile and run
i32 add(i32 a, i32 b)  { return a + b; }
void noop()  { return; }

i32 main() {
    if (add(10, 32) != 42) { return 1; }
    noop();
    return 0;
}
