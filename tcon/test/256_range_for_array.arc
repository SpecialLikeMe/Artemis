// PASS: range-for over a fixed-size C array.
pub fn main() i32 {
    let mut arr: [5]i32;
    arr[0] = 10; arr[1] = 20; arr[2] = 30; arr[3] = 40; arr[4] = 50;

    let mut sum: i32= 0;
    for (let x: i32 : arr) { sum = sum + x; }
    if (sum != 150) { return 1; }

    // Nested range-for
    let mut mat: [3]i32;
    mat[0] = 1; mat[1] = 2; mat[2] = 3;
    let mut prod: i32= 1;
    for (let v: i32 : mat) { prod = prod * v; }
    if (prod != 6) { return 2; }

    return 0;
}
