struct _Pair {
    i32 first;
    i32 second;
}

typedef _Pair Pair;

Pair make_pair(i32 a, i32 b) {
    Pair p;
    p.first  = a;
    p.second = b;
    return p;
}

i32 main() {
    Pair p = make_pair(3, 7);
    if (p.first  != 3) { return 1; }
    if (p.second != 7) { return 2; }
    return 0;
}
