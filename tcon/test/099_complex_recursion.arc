i32 power(i32 base, i32 exp) {
    if (exp == 0) { return 1; }
    if (exp == 1) { return base; }
    i32 half = power(base, exp / 2);
    if (exp % 2 == 0) { return half * half; }
    return base * half * half;
}

i32 main() {
    if (power(2, 0)  != 1)   { return 1; }
    if (power(2, 1)  != 2)   { return 2; }
    if (power(2, 8)  != 256) { return 3; }
    if (power(3, 4)  != 81)  { return 4; }
    if (power(10, 3) != 1000){ return 5; }
    return 0;
}
