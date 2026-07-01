// Generic function with explicit type argument
T identity<T>(T x) { return x; }
T add_vals<T>(T a, T b) { return a + b; }

i32 main() {
    i32  a = identity<i32>(42);
    i64  b = identity<i64>((i64)999);
    bool c = identity<bool>(1);

    if (a != 42)    { return 1; }
    if (b != 999)   { return 2; }
    if (!c)         { return 3; }

    if (add_vals<i32>(3, 4)   != 7)  { return 4; }
    if (add_vals<i64>((i64)10, (i64)20) != 30) { return 5; }
    return 0;
}
