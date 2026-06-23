struct Point {
    i32 x;
    i32 y;
}

i32 main() {
    Point p;
    p.x = 3;
    p.y = 4;
    if (p.x != 3) { return 1; }
    if (p.y != 4) { return 2; }
    p.x = p.x + p.y;
    if (p.x != 7) { return 3; }
    return 0;
}
