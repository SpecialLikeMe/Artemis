i32 main() {
    i32 a = 5;
    i32 b = 10;
    if (!(a < b))  { return 1; }
    if (!(b > a))  { return 2; }
    if (!(a <= 5)) { return 3; }
    if (!(b >= 10)){ return 4; }
    if (a == b)    { return 5; }
    if (!(a != b)) { return 6; }
    return 0;
}
