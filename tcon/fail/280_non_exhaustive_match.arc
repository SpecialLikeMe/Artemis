// FAIL: a match on an enum with no wildcard must name every variant.
enum Color { Red, Green, Blue, }
pub fn main() i32 {
    let mut c: Color = Color.Red;
    match (c) {
        Color::Red   => { return 1; },
        Color::Green => { return 2; },
    }
    return 0;
}
