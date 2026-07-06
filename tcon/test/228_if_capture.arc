// Test: if/else capture syntax: if (cond) |var| {}

i32 g_cap = 0;

i32 main() {
    // Capture the pointer in then-branch
    i32 val = 99;
    i32* ptr = &val;

    // Non-null: capture binds the pointer, dereference it
    if (ptr) |p| {
        g_cap = *p;
    }
    if (g_cap != 99) { return 1; }

    // Null: then-branch should not execute
    i32* null_ptr = (i32*)0;
    g_cap = 0;
    if (null_ptr) |p| {
        g_cap = *p;
    }
    if (g_cap != 0) { return 2; }

    // else capture: fires when condition is false (zero/null)
    g_cap = 0;
    i32 zero = 0;
    if (zero) |x| {
        g_cap = x + 1;
    } else |y| {
        g_cap = 55;
    }
    if (g_cap != 55) { return 3; }

    return 0;
}
