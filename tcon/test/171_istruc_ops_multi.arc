// Multiple operator overloads: -, *, !=
istruc Vec {
    i32 x;
    void __construct__(&self, i32 v) { self.x = v; }
    Vec operator-(&const self, Vec rhs) {
        Vec r;
        r.x = self.x - rhs.x;
        return r;
    }
    Vec operator*(&const self, i32 s) {
        Vec r;
        r.x = self.x * s;
        return r;
    }
    bool operator!=(&const self, Vec rhs) {
        return self.x != rhs.x;
    }
    bool operator<(&const self, Vec rhs) {
        return self.x < rhs.x;
    }
}

i32 main() {
    Vec a(10);
    Vec b(3);

    Vec c = a - b;
    if (c.x != 7)  { return 1; }

    Vec d = a * 4;
    if (d.x != 40) { return 2; }

    if (!(a != b)) { return 3; }
    if (!(b < a))  { return 4; }
    return 0;
}
