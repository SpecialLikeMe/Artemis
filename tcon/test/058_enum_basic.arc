enum Color { Red, Green, Blue }

pub fn main() i32 {
    let mut c: i32= Red;
    if (c != 0)   { return 1; }
    c = Green;
    if (c != 1)   { return 2; }
    c = Blue;
    if (c != 2)   { return 3; }
    return 0;
}
