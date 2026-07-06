// PASS: #[derive(Clone)] synthesises __derive_Clone_Rect returning a copy.

#[derive(Clone)]
istruc Rect {
    i32 w;
    i32 h;
}

i32 main() {
    Rect r;
    r.w = 10;
    r.h = 20;
    Rect r2 = __derive_Clone_Rect(&r);
    return r2.w - 10;  // expect 0
}
