// Three-level inheritance: A -> B -> C
istruc A {
    i32 a;
    void __construct__(&self) { self.a = 1; }
    i32 get_a(&const self) { return self.a; }
}

istruc B : A {
    i32 b;
    void __construct__(&self) { self.a = 1; self.b = 2; }
    i32 get_b(&const self) { return self.b; }
}

istruc C : B {
    i32 c;
    void __construct__(&self) { self.a = 1; self.b = 2; self.c = 3; }
    i32 total(&const self) { return self.a + self.b + self.c; }
}

i32 main() {
    C obj;
    if (obj.get_a() != 1)  { return 1; }
    if (obj.get_b() != 2)  { return 2; }
    if (obj.c       != 3)  { return 3; }
    if (obj.total() != 6)  { return 4; }
    return 0;
}
