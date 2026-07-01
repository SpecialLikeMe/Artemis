istruc Pair {
    i32 first;
    i32 second;

    void __construct__(Pair* self, i32 a, i32 b) : first(a), second(b) {
    }

    i32 sum(const Pair* self) {
        return self.first + self.second;
    }

    i32 product(const Pair* self) {
        return self.first * self.second;
    }
}

istruc Triple {
    i32 a;
    i32 b;
    i32 c;

    void __construct__(Triple* self, i32 x, i32 y, i32 z) : a(x), b(y), c(z) {
    }

    i32 total(const Triple* self) {
        return self.a + self.b + self.c;
    }
}

i32 main() {
    Pair p(3, 7);
    if (p.first   != 3)  { return 1; }
    if (p.second  != 7)  { return 2; }
    if (p.sum()   != 10) { return 3; }
    if (p.product()!= 21){ return 4; }

    Triple t(1, 2, 3);
    if (t.a      != 1) { return 5; }
    if (t.b      != 2) { return 6; }
    if (t.c      != 3) { return 7; }
    if (t.total()!= 6) { return 8; }

    return 0;
}
