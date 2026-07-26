// FAIL: calling a method on a variable that has not been declared
fn main() i32 {
    return nowhere_var.get_value();  // ERROR: nowhere_var undeclared
}
