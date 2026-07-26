pub fn main() i32 {
    let mut x: i32= 5;
    let mut y: i32= ++x;
    if (x != 6) { return 1; }
    if (y != 6) { return 2; }
    let mut z: i32= --x;
    if (x != 5) { return 3; }
    if (z != 5) { return 4; }
    return 0;
}
