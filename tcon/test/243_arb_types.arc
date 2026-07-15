// PASS: new primitive type prefixes — n (natural), z (integer), ch (char), c (complex), q (rational)
extern i32 printf(i8* fmt, ...);

i32 main() {
    // nN = natural (alias for uN)
    n8 a = 200u;
    if (a != 200u) { return 1; }

    // zN = integer (alias for iN)
    z16 b = -500;
    if (b != -500) { return 2; }

    // chN = N-bit character (alias for uN)
    ch8 c = 65u;
    if (c != 65u) { return 3; }

    // cN = complex number (struct with .re and .im)
    c32 z;
    z.re = 3.0;
    z.im = 4.0;
    if (z.re != 3.0f || z.im != 4.0f) { return 4; }

    // c64 = double-precision complex
    c64 w;
    w.re = 1.5;
    w.im = 2.5;
    if (w.re != 1.5 || w.im != 2.5) { return 5; }

    // qN = rational (struct with .num and .den)
    q32 r;
    r.num = 3;
    r.den = 4;
    if (r.num != 3 || r.den != 4) { return 6; }

    return 0;
}
