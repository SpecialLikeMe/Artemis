// FAIL: redeclaring the same variable in the same scope
fn main() i32 {
    let mut x: i32= 1;
    let mut x: i32= 2;  // ERROR: redeclaration
    return x;
}
