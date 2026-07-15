enum Status<T> {
    ok,
    fail,
    pending,
}
i32 main() {
    Status<i32> s1;
    s1 = ok;
    if (s1 != 0) { return 1; }
    Status<f32> s2;
    s2 = fail;
    if (s2 != 1) { return 2; }
    return 0;
}
