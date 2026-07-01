// FAIL: using -> on a non-pointer value
struct Pt { i32 x; }
i32 main() {
    Pt p;
    p.x = 1;
    return p->x;  // ERROR: p is not a pointer
}
