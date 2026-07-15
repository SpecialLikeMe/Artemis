union Pair<T> { T first; i32 second; }
i32 main() {
    Pair<i32> p;
    p.first = 42;
    if (p.second != 42) { return 1; }
    return 0;
}
