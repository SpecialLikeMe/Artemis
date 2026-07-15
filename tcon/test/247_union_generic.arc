// PASS: generic union — fields share memory after monomorphization
union Pair<T> {
    T   a;
    i32 b;
}

i32 main() {
    Pair<i32> p;
    p.a = 0x12345678;
    if (p.b != 0x12345678) { return 1; }

    Pair<f32> q;
    q.b = 0x3f800000; // IEEE 754 1.0f
    if (q.b != 0x3f800000) { return 2; }

    return 0;
}
