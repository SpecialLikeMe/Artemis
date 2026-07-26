struct Vec2 {
    let x: f32;
    let y: f32;
}

fn dot(a: Vec2, b: Vec2) f32 {
    return a.x * b.x + a.y * b.y;
}

pub fn main() i32 {
    let mut u: Vec2;  u.x = 1.0;  u.y = 0.0;
    let mut v: Vec2;  v.x = 0.0;  v.y = 1.0;
    let mut d: f32= dot(u, v);
    if (d != 0.0) { return 1; }

    let mut w: Vec2;  w.x = 3.0;  w.y = 4.0;
    let mut d2: f32= dot(w, w);
    if (d2 != 25.0) { return 2; }
    return 0;
}
