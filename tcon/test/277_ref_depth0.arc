// PASS: ref with no type annotation (depth 0) returns the VALUE, not a pointer.
// ref on a literal returns the literal; ref on a pointer variable dereferences it.
pub fn main() i32 {
    // ref literal → value (not a pointer)
    let x = ref 42;
    if (x != 42) { return 1; }

    // ref lvalue of non-ptr type → value unchanged
    let mut v: i32= 7;
    let y = ref v;
    if (y != 7) { return 2; }

    // ref with explicit value type → value (not a pointer)
    let mut a: i32= 5;
    let z: i32= ref a;
    if (z != 5) { return 3; }

    // ref *int → dereferences once to get i32
    let mut n: i32= 99;
    let mut p: *i32= ref n;
    let derefed = ref p;
    if (derefed != 99) { return 4; }

    // ref with depth > 0 still produces a pointer (existing behavior)
    let mut m: i32= 11;
    let mut q: *i32= ref m;
    if (*q != 11) { return 5; }

    return 0;
}
