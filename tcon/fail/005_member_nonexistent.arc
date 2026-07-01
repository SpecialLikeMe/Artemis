// FAIL: accessing a non-existent member of a class must be rejected
istruc Point {
    i32 x;
    i32 y;
}

i32 main() {
    Point p;
    p.x = 1;
    i32 z = p.z;  // ERROR: 'z' does not exist in Point
    return z;
}
