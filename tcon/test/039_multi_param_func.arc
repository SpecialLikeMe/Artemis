i32 add3(i32 a, i32 b, i32 c) { return a + b + c; }
i32 max2(i32 a, i32 b) { return a > b ? a : b; }

i32 main() {
    if (add3(1, 2, 3)   != 6)  { return 1; }
    if (add3(10, 20, 30) != 60){ return 2; }
    if (max2(7, 3)       != 7) { return 3; }
    if (max2(3, 7)       != 7) { return 4; }
    return 0;
}
