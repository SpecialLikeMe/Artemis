pub fn main() i32 {
    let mut a: i32= 1;
    let mut b: i32= 1;
    if (!(a && b)) { return 1; }
    let mut c: i32= 0;
    if (a && c)    { return 2; }
    if (c && a)    { return 3; }
    return 0;
}
