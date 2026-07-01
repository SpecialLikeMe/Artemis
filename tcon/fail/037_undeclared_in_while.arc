// FAIL: undeclared identifier in while condition
i32 main() {
    while (ghost_cond) {}  // ERROR: ghost_cond undeclared
    return 0;
}
