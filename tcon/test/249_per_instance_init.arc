// Per-instance istruc init: `istruc { ... } x;`
// Tests anonymous istruc with a constructor and methods
istruc {
    i32 value;
    void __construct__(i32 v) { self.value = v; }
    i32 get() { return self.value; }
    void set(i32 v) { self.value = v; }
} obj;

i32 main() {
    istruc { i32 x; i32 y; } pt;
    pt.x = 3;
    pt.y = 4;
    if (pt.x != 3) { return 1; }
    if (pt.y != 4) { return 2; }

    istruc { i32 a; } s1;
    istruc { i32 a; } s2;
    s1.a = 10;
    s2.a = 20;
    if (s1.a != 10) { return 3; }
    if (s2.a != 20) { return 4; }

    return 0;
}
