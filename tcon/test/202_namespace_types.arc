// Test: namespace struct types and intra-namespace type/var references
namespace geom {
    struct Point { let x: i32; let y: i32; }
    struct Rect  { let x: i32; let y: i32; let w: i32; let h: i32; }

    const ORIGIN_X: i32= 0;
    const ORIGIN_Y: i32= 0;

    fn make_point(x: i32, y: i32) Point {
        let mut p: Point;
        p.x = x; p.y = y;
        return p;
    }

    // Intra-namespace: use bare Point / ORIGIN_X without qualification
    fn origin() Point {
        let mut p: Point;
        p.x = ORIGIN_X;
        p.y = ORIGIN_Y;
        return p;
    }

    fn rect_area(r: Rect) i32 { return r.w * r.h; }

    fn make_rect(tl: Point, w: i32, h: i32) Rect {
        let mut r: Rect;
        r.x = tl.x; r.y = tl.y;
        r.w = w; r.h = h;
        return r;
    }
}

pub fn main() i32 {
    let mut p: geom.Point= geom.make_point(3, 4);
    if (p.x != 3) { return 1; }
    if (p.y != 4) { return 2; }

    let mut o: geom.Point= geom.origin();
    if (o.x != 0) { return 3; }
    if (o.y != 0) { return 4; }

    let mut tl: geom.Point= geom.make_point(1, 1);
    let mut r: geom.Rect= geom.make_rect(tl, 5, 3);
    if (geom.rect_area(r) != 15) { return 5; }

    // Namespace constants accessible via .
    if (geom.ORIGIN_X != 0) { return 6; }
    if (geom.ORIGIN_Y != 0) { return 7; }

    return 0;
}
