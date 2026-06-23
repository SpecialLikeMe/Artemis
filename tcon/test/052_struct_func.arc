struct Vec2 {
    f32 x;
    f32 y;
}

f32 dot(Vec2 a, Vec2 b) {
    return a.x * b.x + a.y * b.y;
}

i32 main() {
    Vec2 u;  u.x = 1.0;  u.y = 0.0;
    Vec2 v;  v.x = 0.0;  v.y = 1.0;
    f32 d = dot(u, v);
    if (d != 0.0) { return 1; }

    Vec2 w;  w.x = 3.0;  w.y = 4.0;
    f32 d2 = dot(w, w);
    if (d2 != 25.0) { return 2; }
    return 0;
}
