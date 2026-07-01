// Test: namespace struct types and intra-namespace type/var references
namespace geom {
    struct Point { i32 x; i32 y; }
    struct Rect  { i32 x; i32 y; i32 w; i32 h; }

    constexpr i32 ORIGIN_X = 0;
    constexpr i32 ORIGIN_Y = 0;

    Point make_point(i32 x, i32 y) {
        Point p;
        p.x = x; p.y = y;
        return p;
    }

    // Intra-namespace: use bare Point / ORIGIN_X without qualification
    Point origin() {
        Point p;
        p.x = ORIGIN_X;
        p.y = ORIGIN_Y;
        return p;
    }

    i32 rect_area(Rect r) { return r.w * r.h; }

    Rect make_rect(Point tl, i32 w, i32 h) {
        Rect r;
        r.x = tl.x; r.y = tl.y;
        r.w = w; r.h = h;
        return r;
    }
}

i32 main() {
    geom::Point p = geom::make_point(3, 4);
    if (p.x != 3) { return 1; }
    if (p.y != 4) { return 2; }

    geom::Point o = geom::origin();
    if (o.x != 0) { return 3; }
    if (o.y != 0) { return 4; }

    geom::Point tl = geom::make_point(1, 1);
    geom::Rect  r  = geom::make_rect(tl, 5, 3);
    if (geom::rect_area(r) != 15) { return 5; }

    // Namespace constants accessible via ::
    if (geom::ORIGIN_X != 0) { return 6; }
    if (geom::ORIGIN_Y != 0) { return 7; }

    return 0;
}
