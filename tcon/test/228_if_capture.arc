// Test: if/else capture syntax: if (cond) |var| {}

let mut g_cap: i32= 0;

pub fn main() i32 {
    // Capture the pointer in then-branch
    let mut val: i32= 99;
    let mut ptr: *i32= &val;

    // Non-null: capture binds the pointer, dereference it
    if (ptr) |p| {
        g_cap = *p;
    }
    if (g_cap != 99) { return 1; }

    // Null: then-branch should not execute
    let mut null_ptr: *i32= (i32*)0;
    g_cap = 0;
    if (null_ptr) |p| {
        g_cap = *p;
    }
    if (g_cap != 0) { return 2; }

    // else capture: fires when condition is false (zero/null)
    g_cap = 0;
    let mut zero: i32= 0;
    if (zero) |x| {
        g_cap = x + 1;
    } else |y| {
        g_cap = 55;
    }
    if (g_cap != 55) { return 3; }

    return 0;
}
