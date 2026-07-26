fn clamp(v: i32, lo: i32, hi: i32) i32 {
    if (v < lo) { return lo; }
    if (v > hi) { return hi; }
    return v;
}

pub fn main() i32 {
    if (clamp(5, 0, 10)   != 5)  { return 1; }
    if (clamp(-5, 0, 10)  != 0)  { return 2; }
    if (clamp(15, 0, 10)  != 10) { return 3; }
    return 0;
}
