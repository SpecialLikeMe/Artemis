// PASS: ref operator builds a pointer of depth inferred from LHS type,
// including depth > 1 (multi-level pointers).
pub fn main() i32 {
    let mut x: i32= 7;
    let mut p: *i32= ref x;
    if (*p != 7) { return 1; }

    // Modify through pointer
    *p = 99;
    if (x != 99) { return 2; }

    // ref on rvalue: allocs a temporary
    let mut q: *i32= ref 55;
    if (*q != 55) { return 3; }

    // depth-2: i32** pp = ref x builds a pointer-to-pointer-to-x
    let mut y: i32= 42;
    let mut pp: **i32= ref y;
    if (**pp != 42) { return 4; }

    return 0;
}
