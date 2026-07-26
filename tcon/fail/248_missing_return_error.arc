// FAIL: non-void function with no return statement must be rejected
fn foo() i32 {
    let mut x: i32= 5;
    // no return
}
fn main() i32 { return foo(); }
