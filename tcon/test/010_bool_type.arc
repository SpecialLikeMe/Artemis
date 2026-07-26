pub fn main() i32 {
    let mut t: bool= 1;
    let mut f: bool= 0;
    if (!t) { return 1; }
    if (f)  { return 2; }
    let mut r: bool= t && !f;
    if (!r) { return 3; }
    return 0;
}
