i32 negate(i32 x) { return -x; }

i32 main() {
    if (negate(5)   != -5)  { return 1; }
    if (negate(-10) != 10)  { return 2; }
    if (negate(0)   != 0)   { return 3; }
    i32 x = -(-7);
    if (x != 7)             { return 4; }
    return 0;
}
