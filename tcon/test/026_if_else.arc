pub fn main() i32 {
    let mut x: i32= 5;
    let mut r: i32= 0;
    if (x > 3) {
        r = 1;
    } else {
        r = 2;
    }
    if (r != 1) { return 1; }

    if (x < 3) {
        r = 10;
    } else {
        r = 20;
    }
    if (r != 20) { return 2; }
    return 0;
}
