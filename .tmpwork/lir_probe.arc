pub fn main() i32 {
    let mut a: [4]i32;
    let mut i: i32= 2;
    a[i] = 5;
    let mut s: i32= 0;
    while (i > 0) { s = s + a[i]; i = i - 1; }
    if (s > 3) { return 0; }
    return s;
}
