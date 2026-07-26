// PASS: comptime variable is evaluated and usable at compile time.
pub fn main() i32 {
    const N: i32= 10;
    if (N != 10) { return 1; }

    const M: i32= N * 2;
    if (M != 20) { return 2; }

    let mut arr: [10]i32;
    let mut i: i32= 0;
    while (i < N) { arr[i] = i; i = i + 1; }
    if (arr[9] != 9) { return 3; }

    return 0;
}
