// FAIL: calling a method on a plain struct (structs have no methods)
struct Rect { i32 w; i32 h; }
i32 main() {
    Rect r;
    r.w = 4;
    r.h = 3;
    return r.area();  // ERROR: struct Rect has no method 'area'
}
