istruc Vec2 {
    i32 x;
    i32 y;
}

istruc Rect {
    Vec2 origin;
    i32  width;
    i32  height;
}

i32 main() {
    Vec2 v;
    v.x = 3;
    v.y = 4;
    if (v.x != 3) { return 1; }
    if (v.y != 4) { return 2; }

    Vec2* p = &v;
    (*p).x = 10;
    if (v.x != 10) { return 3; }

    Rect r;
    r.width  = 100;
    r.height = 50;
    if (r.width  != 100) { return 4; }
    if (r.height != 50)  { return 5; }

    return 0;
}
