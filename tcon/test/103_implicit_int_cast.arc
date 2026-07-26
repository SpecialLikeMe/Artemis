pub fn main() i32 {
    let mut a: u8= 2;
    if (a != 2) { return 1; }

    let mut b: u8= 200;
    if (b != 200) { return 2; }

    let mut c: i16= a;
    if (c != 2) { return 3; }

    let mut big: i32= 42;
    let mut small: u8= big;
    if (small != 42) { return 4; }

    let mut x: u8= 0;
    x = 99;
    if (x != 99) { return 5; }

    return 0;
}
