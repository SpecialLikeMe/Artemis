// PASS: #[derive(Clone)] synthesises __derive_Clone_Rect returning a copy.

#[derive(Clone)]
istruc Rect {
    let mut w: i32;
    let mut h: i32;
}

pub fn main() i32 {
    let mut r: Rect;
    r.w = 10;
    r.h = 20;
    let mut r2: Rect= __derive_Clone_Rect(&r);
    return r2.w - 10;  // expect 0
}
