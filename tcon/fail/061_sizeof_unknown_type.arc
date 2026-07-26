// FAIL: sizeof applied to an undeclared type
fn main() i32 {
    let mut s: i32= sizeof(Imaginary);  // ERROR: Imaginary undeclared
    return s;
}
