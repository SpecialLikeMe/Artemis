// FAIL: calling a method on a variable that has not been declared
i32 main() {
    return nowhere_var.get_value();  // ERROR: nowhere_var undeclared
}
