// Test distinct function names (overloading removed; use unique names per arity)
i32 sum0()                    { return 0; }
i32 sum1(i32 a)               { return a; }
i32 sum2(i32 a, i32 b)        { return a + b; }
i32 sum3(i32 a, i32 b, i32 c) { return a + b + c; }

i32 main() {
    if (sum0()        != 0)  { return 1; }
    if (sum1(5)       != 5)  { return 2; }
    if (sum2(3, 4)    != 7)  { return 3; }
    if (sum3(1, 2, 3) != 6)  { return 4; }
    return 0;
}
