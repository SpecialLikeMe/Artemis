fn negate(x: i32) i32 { return -x; }

pub fn main() i32 {
    if (negate(5)   != -5)  { return 1; }
    if (negate(-10) != 10)  { return 2; }
    if (negate(0)   != 0)   { return 3; }
    let mut x: i32= -(-7);
    if (x != 7)             { return 4; }
    return 0;
}
