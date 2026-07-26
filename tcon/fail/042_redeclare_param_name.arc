// FAIL: redeclaring a parameter name inside the function body
fn foo(x: i32) i32 {
    let mut x: i32= x + 1;  // ERROR: redeclaration of 'x'
    return x;
}
fn main() i32 { return foo(0); }
