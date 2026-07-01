// FAIL: undeclared identifier in switch expression
i32 main() {
    switch (unknown_val) { case 0: return 0; }
    return 1;
}
