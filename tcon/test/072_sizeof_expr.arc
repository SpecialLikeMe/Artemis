pub fn main() i32 {
    let mut x: i32= 0;
    if (sizeof(x) != 4) { return 1; }
    let mut y: i64= 0;
    if (sizeof(y) != 8) { return 2; }
    let mut z: i8= 0;
    if (sizeof(z) != 1) { return 3; }
    return 0;
}
