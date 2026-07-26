// EXPECT_FAIL: mixing u8 and i32 in arithmetic without explicit cast is an error
pub fn main() i32 {
    let x: u8 = 5;
    let y: i32 = -10;
    let z = x + y;
    return z;
}
