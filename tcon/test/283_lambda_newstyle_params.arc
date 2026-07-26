// PASS: lambdas support new-style name:type param syntax
@unsafe extern fn printf(fmt: *i8, ...) i32;
pub fn main() i32 {
    let mut add: *(i32, i32)i32 = [](a: i32, b: i32) i32 { return a + b; };
    let mut r: i32 = add(3, 4);
    if (r != 7) { return 1; }
    // Mixed: new-style and old-style should both work
    let mut mul: *(i32)i32 = [](i32 x) i32 { return x * x; };
    if (mul(5) != 25) { return 2; }
    // New-style with different types
    let mut neg: *(i32)i32 = [](n: i32) i32 { return 0 - n; };
    if (neg(10) != -10) { return 3; }
    return 0;
}
