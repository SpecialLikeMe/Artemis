union Val {
    i32 i;
    f32 f;
}

i32 main() {
    Val v;
    v.i = 42;
    if (v.i != 42) { return 1; }
    v.i = 0;
    if (v.i != 0) { return 2; }
    return 0;
}
