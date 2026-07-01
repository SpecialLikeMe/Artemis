// FAIL: undeclared identifier in ternary condition
i32 main() {
    i32 x = shadow_var ? 1 : 0;  // ERROR: shadow_var undeclared
    return x;
}
