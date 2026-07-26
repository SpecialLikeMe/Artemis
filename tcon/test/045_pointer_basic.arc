pub fn main() i32 {
    let mut x: i32= 42;
    let mut p: *i32= &x;
    if (*p != 42) { return 1; }
    *p = 99;
    if (x != 99)  { return 2; }
    return 0;
}
