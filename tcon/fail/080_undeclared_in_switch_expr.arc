// FAIL: undeclared identifier in switch expression
fn main() i32 {
    switch (unknown_val) { case 0: return 0; }
    return 1;
}
