// Test anonymous istruc per-instance init: `istruc { ... } x;`
// PASS PASS PASS PASS
int puts(i8* s);

int main() {
    istruc { int v; } x;
    x.v = 42;
    if (x.v == 42) { puts("PASS"); } else { puts("FAIL v"); }

    istruc { int a; int b; } pt;
    pt.a = 10;
    pt.b = 20;
    if (pt.a == 10) { puts("PASS"); } else { puts("FAIL a"); }
    if (pt.b == 20) { puts("PASS"); } else { puts("FAIL b"); }

    // Multiple anon istrucs in same scope
    istruc { int x; } s1;
    istruc { int x; } s2;
    s1.x = 100;
    s2.x = 200;
    if (s1.x == 100 && s2.x == 200) { puts("PASS"); } else { puts("FAIL multi"); }

    return 0;
}
