// PASS: volatile qualifier marks variables for volatile load/store.
pub fn main() i32 {
    let mut x: volatile i32= 42;
    let mut y: volatile i32= 0;
    y = x + 1;
    if (y != 43) { return 1; }
    return 0;
}
