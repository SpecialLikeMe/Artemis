// FAIL: undeclared identifier in ternary condition
fn main() i32 {
    let mut x: i32= shadow_var ? 1 : 0;  // ERROR: shadow_var undeclared
    return x;
}
