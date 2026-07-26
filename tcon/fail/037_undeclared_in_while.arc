// FAIL: undeclared identifier in while condition
fn main() i32 {
    while (ghost_cond) {}  // ERROR: ghost_cond undeclared
    return 0;
}
