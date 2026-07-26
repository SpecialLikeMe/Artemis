// SMT claim: static array access with constant index is proven GOOD — zero runtime overhead.
// The SMT interval domain knows idx=2 is in [0,4], verdict=GOOD, no check emitted.
@unsafe extern fn printf(fmt: *i8, ...) i32;

pub fn main() i32 {
    let mut arr: [5]i32;
    arr[0] = 10;
    arr[1] = 20;
    arr[2] = 30;
    arr[3] = 40;
    arr[4] = 50;

    // All accesses use constant indices — SMT proves GOOD for each.
    let mut sum: i32= arr[0] + arr[1] + arr[2] + arr[3] + arr[4];
    if (sum != 150) { printf("FAIL sum=%d expected 150\n", sum); return 1; }

    // Constant index at boundary
    let mut first: i32= arr[0];
    let mut last: i32= arr[4];
    if (first != 10 || last != 50) { printf("FAIL boundary\n"); return 2; }

    return 0;
}
