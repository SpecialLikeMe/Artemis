// PASS: generic enum — type-parameterized enum declaration and instantiation
enum Status<T> {
    ok,
    fail,
    pending,
}

enum Maybe<T> {
    nothing,
    something,
}

i32 main() {
    // Different instantiations of the same generic enum
    Status<i32> s1;
    s1 = ok;
    if (s1 != 0) { return 1; }

    Status<f32> s2;
    s2 = fail;
    if (s2 != 1) { return 2; }

    Status<i64> s3;
    s3 = pending;
    if (s3 != 2) { return 3; }

    Maybe<i32> m;
    m = something;
    if (m != 1) { return 4; }

    Maybe<i8*> n;
    n = nothing;
    if (n != 0) { return 5; }

    return 0;
}
