// FAIL: using -> on a non-pointer value
struct Pt { let x: i32; }
fn main() i32 {
    let mut p: Pt;
    p.x = 1;
    return p->x;  // ERROR: p is not a pointer
}
