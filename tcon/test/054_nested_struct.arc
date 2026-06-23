struct Inner {
    i32 a;
    i32 b;
}

struct Outer {
    Inner in;
    i32 c;
}

i32 main() {
    Outer o;
    o.in.a = 1;
    o.in.b = 2;
    o.c    = 3;
    i32 sum = o.in.a + o.in.b + o.c;
    if (sum != 6) { return 1; }
    o.in.b = o.in.a + o.c;
    if (o.in.b != 4) { return 2; }
    return 0;
}
