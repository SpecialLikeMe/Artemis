pub fn main() i32 {
    let mut x: i32= 1;
    let mut r: i32= 0;
    switch (x) {
        case 1: r = r + 1;
        case 2: r = r + 2;
        default: r = r + 4;
    }
    if (r != 7) { return 1; }
    return 0;
}
