i32 main() {
    i32 a = 1;
    {
        i32 b = 2;
        {
            i32 c = 3;
            a = a + b + c;
        }
        a = a + b;
    }
    if (a != 8) { return 1; }
    return 0;
}
