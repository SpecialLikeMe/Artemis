// FAIL: calling a method on a plain struct (structs have no methods)
struct Rect { let w: i32; let h: i32; }
fn main() i32 {
    let mut r: Rect;
    r.w = 4;
    r.h = 3;
    return r.area();  // ERROR: struct Rect has no method 'area'
}
