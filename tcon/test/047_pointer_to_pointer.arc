pub fn main() i32 {
    let mut x: i32= 55;
    let mut p: *i32= &x;
    let mut pp: **i32= &p;
    if (**pp != 55)  { return 1; }
    **pp = 77;
    if (x != 77)     { return 2; }
    if (*p != 77)    { return 3; }
    return 0;
}
