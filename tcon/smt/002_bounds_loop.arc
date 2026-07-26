// SMT claim: loop with constant bounds — induction variable proven in [0, N-1], verdict=GOOD.
// After widening: interval for i is [0, 9], array size=10 → bounds check proven GOOD.
@unsafe extern fn printf(fmt: *i8, ...) i32;

pub fn main() i32 {
    let mut arr: [10]i32;

    // Fill: arr[i] = i*i
    let mut i: i32= 0;
    while (i < 10) {
        arr[i] = i * i;
        i = i + 1;
    }

    // Verify spot checks at constant indices (SMT: idx is constant → GOOD)
    if (arr[0] != 0)  { printf("FAIL arr[0]=%d\n", arr[0]);  return 1; }
    if (arr[1] != 1)  { printf("FAIL arr[1]=%d\n", arr[1]);  return 2; }
    if (arr[3] != 9)  { printf("FAIL arr[3]=%d\n", arr[3]);  return 3; }
    if (arr[9] != 81) { printf("FAIL arr[9]=%d\n", arr[9]);  return 4; }

    // Sum of squares 0..9 = 285
    let mut sum: i32= 0;
    let mut j: i32= 0;
    while (j < 10) {
        sum = sum + arr[j];
        j = j + 1;
    }
    if (sum != 285) { printf("FAIL sum=%d expected 285\n", sum); return 5; }

    return 0;
}
