// Test: optional parentheses around conditions for if/while/for/switch.

pub fn main() i32 {
    let mut x: i32= 0;

    // if without parens
    if x == 0 { x = 1; }
    if (x != 1) { return 1; }

    // while without parens
    let mut i: i32= 0;
    while i < 3 { i = i + 1; }
    if (i != 3) { return 2; }

    // for without parens (classic form)
    let mut sum: i32= 0;
    for i = 0; i < 4; i = i + 1 { sum = sum + i; }
    if (sum != 6) { return 3; }

    // switch without parens
    let mut r: i32= 0;
    switch x {
        case 1: r = 10; break;
        default: r = 0;
    }
    if (r != 10) { return 4; }

    return 0;
}
