typedef i32 Score;
typedef f64 Real;

Score triple(Score s) { return s * 3; }

i32 main() {
    Score s = 10;
    if (triple(s) != 30) { return 1; }

    Real r = 2.5;
    Real r2 = r * r;
    if (r2 != 6.25) { return 2; }
    return 0;
}
