// FAIL: undeclared identifier used as array index
fn main() i32 {
    let mut arr: [5]i32;
    arr[0] = 1;
    return arr[phantom_idx];  // ERROR: phantom_idx undeclared
}
