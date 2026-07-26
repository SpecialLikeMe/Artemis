// inline and storage class keywords
fn square(x: i32) i32 { return x * x; }
fn cube(x: i32) i32   { return x * x * x; }

pub fn main() i32 {
    let mut a: i32= 4;
    let mut b: i32= 3;

    if (square(a) != 16) { return 1; }
    if (cube(b)   != 27) { return 2; }

    let mut c: i32= square(a) + cube(b);
    if (c != 43) { return 3; }
    return 0;
}
