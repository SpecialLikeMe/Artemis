// Test new primitive type prefixes: n, z, ch, c (complex), q (rational)
// PASS PASS PASS PASS PASS PASS
int puts(i8* s);
int printf(i8* fmt, ...);

int main() {
    // nN = natural (alias for uN)
    n8 a = 200u;
    if (a == 200u) { puts("PASS"); } else { puts("FAIL n8"); }

    // zN = integer (alias for iN)
    z16 b = -500;
    if (b == -500) { puts("PASS"); } else { puts("FAIL z16"); }

    // chN = N-bit character (alias for uN)
    ch8 c = 'A';
    if (c == 65u) { puts("PASS"); } else { puts("FAIL ch8"); }

    // cN = complex number (struct with .re and .im fields)
    c32 z;
    z.re = 3.0;
    z.im = 4.0;
    if (z.re == 3.0f && z.im == 4.0f) { puts("PASS"); } else { puts("FAIL c32"); }

    // c64 = complex double
    c64 w;
    w.re = 1.5;
    w.im = 2.5;
    if (w.re == 1.5 && w.im == 2.5) { puts("PASS"); } else { puts("FAIL c64"); }

    // qN = rational number (struct with .num and .den fields)
    q64 r;
    r.num = 7;
    r.den = 3;
    if (r.num == 7 && r.den == 3) { puts("PASS"); } else { puts("FAIL q64"); }

    return 0;
}
