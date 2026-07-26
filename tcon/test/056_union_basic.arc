union Val {
    let i: i32;
    let f: f32;
}

pub fn main() i32 {
    let mut v: Val;
    v.i = 42;
    if (v.i != 42) { return 1; }
    v.i = 0;
    if (v.i != 0) { return 2; }
    return 0;
}
