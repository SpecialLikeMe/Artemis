// FAIL: accessing a non-existent field in a struct
struct Vec3 { f32 x; f32 y; f32 z; }
i32 main() {
    Vec3 v;
    v.x = 1.0;
    return (i32)v.w;  // ERROR: no field 'w'
}
