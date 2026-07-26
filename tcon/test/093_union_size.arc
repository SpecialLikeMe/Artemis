union Big {
    let a: i64;
    let b: i32;
    let c: i8;
}

pub fn main() i32 {
    if (sizeof(Big) < 8)         { return 1; }
    if (sizeof(Big) < sizeof(i64)) { return 2; }
    return 0;
}
