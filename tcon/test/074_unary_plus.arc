pub fn main() i32 {
    let mut x: i32= -5;
    let mut y: i32= +x;
    if (y != -5) { return 1; }
    let mut z: i32= +42;
    if (z != 42) { return 2; }
    return 0;
}
