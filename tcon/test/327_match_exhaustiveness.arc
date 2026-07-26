// Test: a match covering every enum variant compiles without needing a '_' arm.
// The complementary case (a missing variant is reported) is a compile-time error and
// so lives in tcon/fail rather than here.
@unsafe extern fn printf(fmt: *i8, ...) i32;

enum Color { Red, Green, Blue, }

fn code(c: Color) i32 {
    let mut r: i32= 0;
    match (c) {
        Color::Red   => { r = 1; },
        Color::Green => { r = 2; },
        Color::Blue  => { r = 3; },
    }
    return r;
}

fn code_wild(c: Color) i32 {
    let mut r: i32= 0;
    // A wildcard arm covers the rest, so partial coverage is fine here.
    match (c) {
        Color::Red => { r = 1; },
        _          => { r = 9; },
    }
    return r;
}

pub fn main() i32 {
    let mut a: Color = Color.Red;
    let mut b: Color = Color.Green;
    let mut c: Color = Color.Blue;

    if (code(a) != 1) { return 1; }
    if (code(b) != 2) { return 2; }
    if (code(c) != 3) { return 3; }

    if (code_wild(a) != 1) { return 4; }
    if (code_wild(c) != 9) { return 5; }
    return 0;
}
