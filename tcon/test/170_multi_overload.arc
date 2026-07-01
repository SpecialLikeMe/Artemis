// Three overloads of the same function name
i32 sum()              { return 0; }
i32 sum(i32 a)         { return a; }
i32 sum(i32 a, i32 b)  { return a + b; }
i32 sum(i32 a, i32 b, i32 c) { return a + b + c; }

i32 main() {
    if (sum()        != 0)  { return 1; }
    if (sum(5)       != 5)  { return 2; }
    if (sum(3, 4)    != 7)  { return 3; }
    if (sum(1, 2, 3) != 6)  { return 4; }
    return 0;
}
