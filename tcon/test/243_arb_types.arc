// PASS: new primitive type prefixes — n (natural), z (integer), ch (char), c (complex), q (rational)
@unsafe extern fn printf(fmt: *i8, ...) i32;

pub fn main() i32 {
    // nN = natural (alias for uN)
    let mut a: n8= 200u;
    if (a != 200u) { return 1; }

    // zN = integer (alias for iN)
    let mut b: z16= -500;
    if (b != -500) { return 2; }

    // chN = N-bit character (alias for uN)
    let mut c: ch8= 65u;
    if (c != 65u) { return 3; }

    // cN = complex number (struct with .re and .im)
    let mut z: c32;
    z.re = 3.0;
    z.im = 4.0;
    if (z.re != 3.0f || z.im != 4.0f) { return 4; }

    // c64 = double-precision complex
    let mut w: c64;
    w.re = 1.5;
    w.im = 2.5;
    if (w.re != 1.5 || w.im != 2.5) { return 5; }

    // qN = rational (struct with .num and .den)
    let mut r: q32;
    r.num = 3;
    r.den = 4;
    if (r.num != 3 || r.den != 4) { return 6; }

    return 0;
}
