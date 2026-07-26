// FAIL: accessing a non-existent field in a struct
struct Vec3 { let x: f32; let y: f32; let z: f32; }
fn main() i32 {
    let mut v: Vec3;
    v.x = 1.0;
    return (i32)v.w;  // ERROR: no field 'w'
}
