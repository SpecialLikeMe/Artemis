pub fn main() i32 {
    let mut a: i32= 0;
    if (!(!a)) { return 1; }
    let mut b: i32= 5;
    if (!b)    { return 2; }
    if (!!a)   { return 3; }
    return 0;
}
