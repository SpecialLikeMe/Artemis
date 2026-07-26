// FAIL: using an undeclared type must be rejected
fn main() i32 {
    let mut x: Blarg;  // ERROR: 'Blarg' is not a known type
    return 0;
}
