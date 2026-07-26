// PASS: #[derive(Default)] synthesises __derive_Default_Vec2 returning zeroed struct.

#[derive(Default)]
istruc Vec2 {
    let mut x: i32;
    let mut y: i32;
}

pub fn main() i32 {
    let mut v: Vec2= __derive_Default_Vec2();
    return v.x + v.y;  // expect 0
}
