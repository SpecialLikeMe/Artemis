// PASS: #[derive(Debug)] on an istruc synthesises __derive_Debug_Point.

#[derive(Debug)]
istruc Point {
    i32 x;
    i32 y;
}

i32 main() {
    Point p;
    p.x = 3;
    p.y = 4;
    __derive_Debug_Point(&p);
    return 0;
}
