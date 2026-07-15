// PASS: first-class type aliases via comptime type
comptime type MyInt = i32;
comptime type MyFloat = f64;

istruc Pair {
    i32 x;
    i32 y;
}
comptime type PairAlias = Pair;

i32 main() {
    MyInt a = 100;
    if (a != 100) { return 1; }

    MyFloat f = 3.14;
    if (f < 3.0) { return 2; }

    PairAlias p;
    p.x = 10;
    p.y = 20;
    if (p.x + p.y != 30) { return 3; }

    return 0;
}
