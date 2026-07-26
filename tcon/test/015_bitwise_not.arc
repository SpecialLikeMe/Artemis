pub fn main() i32 {
    let mut a: i8= 0;
    let mut b: i8= ~a;
    if (b != -1) { return 1; }
    let mut c: i32= ~0;
    if (c != -1) { return 2; }
    return 0;
}
