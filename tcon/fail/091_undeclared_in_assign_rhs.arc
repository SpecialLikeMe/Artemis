// FAIL: undeclared identifier on the right-hand side of an assignment
i32 main() {
    i32 x = 0;
    x = ghost_value;  // ERROR: ghost_value undeclared
    return x;
}
