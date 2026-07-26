// FAIL: casting to an undeclared type
fn main() i32 {
    let mut x: i32= (SomeUnknown)5;  // ERROR: SomeUnknown undeclared
    return x;
}
