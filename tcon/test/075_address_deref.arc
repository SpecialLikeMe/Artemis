i32 main() {
    i32 a = 10;
    i32 b = 20;
    i32* pa = &a;
    i32* pb = &b;
    i32 sum = *pa + *pb;
    if (sum != 30) { return 1; }
    *pa = *pb + 5;
    if (a != 25)   { return 2; }
    return 0;
}
