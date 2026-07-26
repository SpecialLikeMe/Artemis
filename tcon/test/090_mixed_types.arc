pub fn main() i32 {
    let mut i: i32= 10;
    let mut f: f64= (f64)i;
    f = f / 3.0;
    let mut back: i32= (i32)f;
    if (back != 3) { return 1; }

    let mut b: i8= 127;
    let mut promoted: i32= (i32)b;
    if (promoted != 127) { return 2; }
    return 0;
}
