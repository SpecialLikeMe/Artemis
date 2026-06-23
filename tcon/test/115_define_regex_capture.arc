@define <MAX\(([^,]+),([^)]+)\)> <%1 > %2 ? %1 : %2>

i32 main() {
    i32 a = 10;
    i32 b = 20;
    i32 m = MAX(a,b);
    if (m != 20) { return 1; }
    i32 c = 99;
    i32 d = 3;
    i32 n = MAX(c,d);
    if (n != 99) { return 2; }
    return 0;
}
