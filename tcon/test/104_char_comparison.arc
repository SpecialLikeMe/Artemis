pub fn main() i32 {
    let mut a: char= 'A';
    let mut z: char= 'Z';
    if (a >= z) { return 1; }
    if (a != 65) { return 2; }
    if (z != 90) { return 3; }
    let mut mid: char= 'M';
    if (mid < a) { return 4; }
    if (mid > z) { return 5; }
    return 0;
}
