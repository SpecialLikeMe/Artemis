istruc Vec2 {
    let mut x: i32;
    let mut y: i32;
}

istruc Rect {
    let mut origin: Vec2;
    let mut width: i32;
    let mut height: i32;
}

pub fn main() i32 {
    let mut v: Vec2;
    v.x = 3;
    v.y = 4;
    if (v.x != 3) { return 1; }
    if (v.y != 4) { return 2; }

    let mut p: *Vec2= &v;
    (*p).x = 10;
    if (v.x != 10) { return 3; }

    let mut r: Rect;
    r.width  = 100;
    r.height = 50;
    if (r.width  != 100) { return 4; }
    if (r.height != 50)  { return 5; }

    return 0;
}
