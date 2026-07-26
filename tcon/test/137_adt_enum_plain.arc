// 137: ADT enum — plain variant (C-style tag only)
enum color {
    red,
    green,
    blue,
}

pub fn main() i32 {
    let mut c: i32= color.green;
    if (c != color.green) { return 1; }
    if (c == color.red)   { return 2; }
    return 0;
}
