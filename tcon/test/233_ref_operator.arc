// Test the `ref` operator — context-aware address-of
// PASS PASS PASS PASS
fn puts(s: *i8) int;
fn printf(fmt: *i8, ...) int;

pub fn main() int {
    // ref on lvalue: p = &x
    let mut x: int= 42;
    let mut p: *int= ref x;
    if (*p == 42) { puts("PASS"); } else { puts("FAIL ref basic"); }

    // Writing through ref affects original
    *p = 100;
    if (x == 100) { puts("PASS"); } else { puts("FAIL ref write-through"); }

    // ref on rvalue → allocates a temp
    let mut q: *int= ref 77;
    if (*q == 77) { puts("PASS"); } else { puts("FAIL ref rvalue"); }

    // ref on expression result
    let mut a: int= 5;
    let mut b: int= 6;
    let mut r: *int= ref a;
    if (*r == 5) { puts("PASS"); } else { puts("FAIL ref expr"); }

    return 0;
}
