// sizeof applied to expressions and pointer types
pub fn main() i32 {
    let mut x: i32= 0;
    if (sizeof(x)   != 4) { return 1; }
    if (sizeof(i32*) != 8) { return 2; }  // pointer is 8 bytes on 64-bit
    let mut y: i64= 0;
    if (sizeof(y)   != 8) { return 3; }
    return 0;
}
