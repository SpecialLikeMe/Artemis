// Generic istruc with constructor and methods
istruc Pair<T> {
    T first;
    T second;

    void __construct__(Pair* self, T a, T b) {
        self.first  = a;
        self.second = b;
    }

    T sum(const Pair* self) { return self.first + self.second; }
    T diff(const Pair* self) { return self.first - self.second; }
}

i32 main() {
    Pair<i32> p(10, 3);
    if (p.sum()  != 13) { return 1; }
    if (p.diff() != 7)  { return 2; }
    if (p.first  != 10) { return 3; }

    Pair<i64> q((i64)100, (i64)25);
    if (q.sum()  != 125) { return 4; }
    if (q.diff() != 75)  { return 5; }
    return 0;
}
