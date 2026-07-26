// FAIL: member access on a primitive type
fn main() i32 {
    let mut x: i32= 5;
    let mut y: i32= x.value;  // ERROR: i32 has no members
    return y;
}
