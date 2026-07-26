// PASS: 'as' keyword for safe explicit type conversion.
pub fn main() i32 {
    let mut foo: i32= 2;
    let mut bar: f64= 2.5;
    let mut baz: i32= foo + bar as i32;   // f64 -> i32: truncates to 2
    if (baz != 4) { return 1; }

    let mut x: i64= 1000000;
    let mut y: i32= x as i32;
    if (y != 1000000) { return 2; }

    let mut f: f32= 3.14;
    let mut i: i32= f as i32;
    if (i != 3) { return 3; }

    let mut p: *i8= (i8*)0;
    let mut addr: u64= p as u64;
    if (addr != 0) { return 4; }

    return 0;
}
