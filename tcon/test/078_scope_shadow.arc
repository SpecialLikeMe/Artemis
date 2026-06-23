i32 x = 10;

i32 main() {
    if (x != 10) { return 1; }
    {
        i32 x = 20;
        if (x != 20) { return 2; }
    }
    if (x != 10) { return 3; }
    {
        i32 x = 30;
        x = x + 1;
        if (x != 31) { return 4; }
    }
    if (x != 10) { return 5; }
    return 0;
}
