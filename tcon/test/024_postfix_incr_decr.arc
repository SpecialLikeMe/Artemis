pub fn main() i32 {
    let mut x: i32= 5;
    let mut y: i32= x++;
    if (y != 5) { return 1; }
    if (x != 6) { return 2; }
    let mut z: i32= x--;
    if (z != 6) { return 3; }
    if (x != 5) { return 4; }
    return 0;
}
