// FAIL: array of an undeclared element type
fn main() i32 {
    let mut arr: [5]Phantom;  // ERROR: Phantom undeclared
    return 0;
}
