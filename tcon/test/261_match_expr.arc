// PASS: match used as an expression
pub fn main() i32 {
    let mut x: i32= 2;
    let mut name: i32= match(x) {
        1 => 10,
        2 => 20,
        _ => 99,
    };
    if (name != 20) { return 1; }

    let mut y: i32= match(x + 1) {
        3 => 100,
        _ => 0,
    };
    if (y != 100) { return 2; }

    return 0;
}
