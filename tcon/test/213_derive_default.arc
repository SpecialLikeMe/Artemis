// PASS: #[derive(Default)] synthesises __derive_Default_Vec2 returning zeroed struct.

#[derive(Default)]
istruc Vec2 {
    i32 x;
    i32 y;
}

i32 main() {
    Vec2 v = __derive_Default_Vec2();
    return v.x + v.y;  // expect 0
}
