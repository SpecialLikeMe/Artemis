// FAIL: using a for-loop variable after the loop ends
fn main() i32 {
    for (let mut i: i32 = 0; i < 5; i = i + 1) {}
    return i;  // ERROR: i is out of scope
}
